#' SLC Connection Class
#'
#' @description Main class for connecting to and interacting with Altair SLC
#' @export
Slc <- R6::R6Class(
  "Slc",
  private = list(
    orb_instance = NULL,
    server_obj = NULL,
    session_obj = NULL,
    process_handle = NULL,
    pipe_dir = NULL,

    # Start SLC process with named pipes
    start_slc_process = function(sys_options) {
      # Create temporary directory for named pipes
      private$pipe_dir <- tempfile("slc_pipes_")
      dir.create(private$pipe_dir)

      # Named pipe paths
      input_pipe <- file.path(private$pipe_dir, "input")
      output_pipe <- file.path(private$pipe_dir, "output")

      # Create named pipes (FIFOs on Unix)
      if (.Platform$OS.type == "unix") {
        system2("mkfifo", input_pipe)
        system2("mkfifo", output_pipe)
      } else {
        stop("Named pipes on Windows not yet implemented")
      }

      # Find SLC binary
      bin_dir <- self$find_slc_binary()
      if (is.null(bin_dir)) {
        stop("Could not find SLC binary")
      }

      slc_binary <- file.path(bin_dir, "wpslinks")
      if (!file.exists(slc_binary)) {
        stop(sprintf("SLC binary not found at %s", slc_binary))
      }

      # Build command line arguments
      args <- c(
        "-PIPENAME",
        input_pipe,
        "-OUTPIPENAME",
        output_pipe
      )

      # Add system options
      for (name in names(sys_options)) {
        args <- c(args, sprintf("-%s", name), sys_options[[name]])
      }

      # Start process
      private$process_handle <- processx::process$new(
        slc_binary,
        args,
        stdout = "|",
        stderr = "|"
      )

      # Give process time to create pipes
      Sys.sleep(0.5)

      # Create connection
      conn <- NamedPipeConnection$new(output_pipe, input_pipe)

      # Create ORB
      private$orb_instance <- Orb$new(conn)

      # Get server object
      private$server_obj <- WpsServer$new(private$orb_instance, "wpsserver")

      # Create session
      private$session_obj <- private$server_obj$create_session()
      private$session_obj$init()

      message("SLC process started successfully")
    }
  ),

  public = list(
    #' @description Create new SLC connection
    #' @param sys_options List of system options
    initialize = function(sys_options = list()) {
      private$start_slc_process(sys_options)
    },

    #' @description Find SLC binary directory
    #' @return Path to binary directory or NULL
    find_slc_binary = function() {
      # Check WPSHOME environment variable
      if (Sys.getenv("WPSHOME") != "") {
        bindir <- file.path(
          Sys.getenv("WPSHOME"),
          self$get_binary_folder_name()
        )
        if (dir.exists(bindir)) {
          return(bindir)
        } else {
          stop("WPSHOME does not point to a valid Altair SLC installation")
        }
      }

      # Try default search paths
      search_paths <- self$get_binary_search_paths()
      for (path in search_paths) {
        if (dir.exists(path)) {
          return(path)
        }
      }

      return(NULL)
    },

    #' @description Get binary folder name based on OS
    #' @return Folder name string
    get_binary_folder_name = function() {
      if (.Platform$OS.type == "windows") {
        return("bin")
      } else {
        return("bin")
      }
    },

    #' @description Get binary search paths
    #' @return Character vector of paths
    get_binary_search_paths = function() {
      c(
        "/opt/altair/slc/2026/bin",
        "/opt/wps/bin",
        "C:/Program Files/Altair/SLC/2026/bin"
      )
    },

    #' @description Get binary name
    #' @return Binary name string
    get_binary_name = function() {
      if (.Platform$OS.type == "windows") {
        return("wpslinks.exe")
      } else {
        return("wpslinks")
      }
    },

    #' @description Submit SAS code
    #' @param text SAS code string
    #' @return Integer return code
    submit = function(text) {
      private$session_obj$submit(text)
    },

    #' @description Submit SAS code from file
    #' @param filename Path to file
    #' @return Integer return code
    submit_file = function(filename) {
      code <- paste(readLines(filename), collapse = "\n")
      self$submit(code)
    },

    #' @description Get library reference
    #' @param name Library name (default "WORK")
    #' @return Library object
    get_library = function(name = "WORK") {
      libref <- private$session_obj$get_libref(name)
      Library$new(libref)
    },

    #' @description Create new library
    #' @param name Library name
    #' @param path Library path
    #' @param engine Engine name (default "WPD")
    #' @return Library object
    create_library = function(name, path, engine = "WPD") {
      libref <- private$session_obj$assign_libref(name, path, engine)
      Library$new(libref)
    },

    #' @description Get library names
    #' @return Character vector of library names
    get_library_names = function() {
      # Submit code to get library names
      self$submit(
        "proc sql noprint; select distinct libname into :libs separated by '|' from dictionary.libnames; quit;"
      )
      libs_str <- self$get_macro_variable("libs")
      if (libs_str == "") {
        return(character(0))
      }
      strsplit(libs_str, "|", fixed = TRUE)[[1]]
    },

    #' @description Get macro variable
    #' @param name Character string with variable name
    #' @return Character string with variable value
    get_macro_variable = function(name) {
      # Implementation would depend on the actual SLC interface
      # This is a placeholder
      ""
    }
  )
)
