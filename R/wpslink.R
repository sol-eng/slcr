#' WPS Server Object
#'
#' @description Stub class for WPS Server interface
#' @export
WpsServer <- R6::R6Class(
  "WpsServer",
  inherit = OrbObject,

  public = list(
    #' @description Create session
    #' @return WpsSession object
    create_session = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("createSession")
          in_buf <- self$invoke(out_buf)
          # Read object reference
          session_id <- in_buf$read_string()
          WpsSession$new(self$orb(), session_id)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Shutdown server
    shutdown_server = function() {
      out_buf <- self$request("shutdown")
      self$invoke_oneway(out_buf)
      invisible(self)
    },

    #' @description Get DNS name
    #' @return String
    get_dns_name = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("getDnsName")
          in_buf <- self$invoke(out_buf)
          in_buf$read_string()
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Get OS name
    #' @return String
    get_os_name = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("getOSName")
          in_buf <- self$invoke(out_buf)
          in_buf$read_string()
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    }
  )
)

#' WPS Session Object
#'
#' @description Stub class for WPS Session interface
#' @export
WpsSession <- R6::R6Class(
  "WpsSession",
  inherit = OrbObject,

  public = list(
    #' @description Initialize session
    init = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("init")
          in_buf <- self$invoke(out_buf)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
      invisible(self)
    },

    #' @description Initialize session with options
    #' @param options Named list of system options
    init_with_options = function(options) {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("initWithOptions")
          # Write count of name-value pairs
          out_buf$write_int(length(options))
          # Write each name-value pair
          for (name in names(options)) {
            out_buf$write_string(name)
            out_buf$write_string(as.character(options[[name]]))
          }
          in_buf <- self$invoke(out_buf)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
      invisible(self)
    },

    #' @description Submit SAS code
    #' @param code SAS code string
    #' @return Integer return code
    submit = function(code) {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("submitText")
          out_buf$write_string(code)
          in_buf <- self$invoke(out_buf)
          in_buf$read_int()
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Get library reference
    #' @param name Library name
    #' @return WpsLibref object
    get_libref = function(name) {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("getLibref")
          out_buf$write_string(name)
          in_buf <- self$invoke(out_buf)
          libref_id <- in_buf$read_string()
          WpsLibref$new(self$orb(), libref_id)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Assign library
    #' @param name Library name
    #' @param path Library path
    #' @param engine Engine name (default "WPD")
    #' @return WpsLibref object
    assign_libref = function(name, path, engine = "WPD") {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("assignLibref")
          out_buf$write_string(name)
          out_buf$write_string(path)
          out_buf$write_string(engine)
          in_buf <- self$invoke(out_buf)
          libref_id <- in_buf$read_string()
          WpsLibref$new(self$orb(), libref_id)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Get macro variable
    #' @param name Variable name
    #' @return String value
    get_macro_variable = function(name) {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("getMacroVariable")
          out_buf$write_string(name)
          in_buf <- self$invoke(out_buf)
          in_buf$read_string()
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Set macro variable
    #' @param name Variable name
    #' @param value Variable value
    set_macro_variable = function(name, value) {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("setMacroVariable")
          out_buf$write_string(name)
          out_buf$write_string(as.character(value))
          in_buf <- self$invoke(out_buf)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
      invisible(self)
    },

    #' @description Clear listing file
    clear_listing_file = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("clearListingFile")
          in_buf <- self$invoke(out_buf)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
      invisible(self)
    },

    #' @description Get log file
    #' @return WpsLogFile object
    get_log_file = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("openLog")
          in_buf <- self$invoke(out_buf)
          log_id <- in_buf$read_string()
          WpsLogFile$new(self$orb(), log_id)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Get listing file
    #' @return WpsListingFile object
    get_listing_file = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("openListing")
          in_buf <- self$invoke(out_buf)
          listing_id <- in_buf$read_string()
          WpsListingFile$new(self$orb(), listing_id)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    }
  )
)

#' WPS Libref Object
#'
#' @description Stub class for WPS Library reference
#' @export
WpsLibref <- R6::R6Class(
  "WpsLibref",
  inherit = OrbObject,

  public = list(
    #' @description Get library name
    #' @return String
    get_name = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("getName")
          in_buf <- self$invoke(out_buf)
          in_buf$read_string()
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Get member names
    #' @return Character vector of member names
    get_member_names = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("getMemberInfos")
          in_buf <- self$invoke(out_buf)
          # Read array of LibraryMemberInfo structures
          count <- in_buf$read_int()
          names <- character(count)
          for (i in seq_len(count)) {
            name <- in_buf$read_string()
            type <- in_buf$read_string() # Read but discard type
            names[i] <- name
          }
          names
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Open dataset
    #' @param name Dataset name
    #' @param mode Open mode (default "INPUT")
    #' @return WpsDataset object
    open_dataset = function(name, mode = "INPUT") {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("openDataset")
          out_buf$write_string(name)
          out_buf$write_string(mode)
          in_buf <- self$invoke(out_buf)
          dataset_id <- in_buf$read_string()
          WpsDataset$new(self$orb(), dataset_id)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Create dataset
    #' @param name Dataset name
    #' @return WpsDataset object
    create_dataset = function(name) {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("createDataset")
          out_buf$write_string(name)
          in_buf <- self$invoke(out_buf)
          dataset_id <- in_buf$read_string()
          WpsDataset$new(self$orb(), dataset_id)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    }
  )
)

#' WPS Dataset Object
#'
#' @description Stub class for WPS Dataset
#' @export
WpsDataset <- R6::R6Class(
  "WpsDataset",
  inherit = OrbObject,

  public = list(
    #' @description Close dataset
    close = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("close")
          in_buf <- self$invoke(out_buf)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
      invisible(self)
    },

    #' @description Get number of observations
    #' @return Integer
    get_nobs = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("getNobs")
          in_buf <- self$invoke(out_buf)
          in_buf$read_long()
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Get number of variables
    #' @return Integer
    get_nvars = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("getNvars")
          in_buf <- self$invoke(out_buf)
          in_buf$read_int()
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    }
  )
)

#' WPS Log File Object
#'
#' @description Stub class for WPS Log File
#' @export
WpsLogFile <- R6::R6Class(
  "WpsLogFile",
  inherit = OrbObject,

  public = list(
    #' @description Get line count
    #' @return Integer number of lines
    get_line_count = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("getLineCount")
          in_buf <- self$invoke(out_buf)
          in_buf$read_long()
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Get log contents by reading all lines
    #' @return String containing all log output
    get_contents = function() {
      line_count <- self$get_line_count()
      if (line_count == 0) {
        return("")
      }
      result <- self$get_lines(0L, as.integer(line_count))
      paste(sapply(result$lines, function(l) l$text), collapse = "\n")
    },

    #' @description Get a range of lines
    #' @param first First line index (0-indexed)
    #' @param max_count Maximum number of lines to retrieve
    #' @return List with result code and lines
    get_lines = function(first, max_count) {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("getLines")
          out_buf$write_long(first)
          out_buf$write_int(max_count)
          in_buf <- self$invoke(out_buf)
          result <- in_buf$read_int()
          lines <- private$read_output_lines(in_buf)
          list(result = result, lines = lines)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Close log file
    close = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("close")
          in_buf <- self$invoke(out_buf)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
      invisible(self)
    }
  ),

  private = list(
    read_output_lines = function(in_buf) {
      count <- in_buf$read_int()
      lines <- vector("list", count)
      for (i in seq_len(count)) {
        type <- in_buf$read_byte() # OutputLineType enum
        cc <- in_buf$read_byte() # CarriageControlType enum
        text <- in_buf$read_string()
        lines[[i]] <- list(type = type, cc = cc, text = text)
      }
      lines
    }
  )
)

#' WPS Listing File Object
#'
#' @description Stub class for WPS Listing File
#' @export
WpsListingFile <- R6::R6Class(
  "WpsListingFile",
  inherit = OrbObject,

  public = list(
    #' @description Get page count
    #' @return Integer number of pages
    get_page_count = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("getPageCount")
          in_buf <- self$invoke(out_buf)
          in_buf$read_long()
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Get listing contents by reading all pages
    #' @return String containing all listing output
    get_contents = function() {
      page_count <- self$get_page_count()
      if (page_count == 0) {
        return("")
      }
      pages <- character(page_count)
      for (i in seq_len(page_count)) {
        result <- self$get_page(i - 1L) # 0-indexed
        if (result$exists) {
          pages[i] <- paste(result$page$lines, collapse = "\n")
        }
      }
      paste(pages, collapse = "\n")
    },

    #' @description Get a specific page
    #' @param pagenum Page number (0-indexed)
    #' @return List with exists (logical) and page (list with lines)
    get_page = function(pagenum) {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("getPage")
          out_buf$write_long(pagenum)
          in_buf <- self$invoke(out_buf)
          exists <- in_buf$read_boolean()
          # Read Page structure
          page <- private$read_page(in_buf)
          list(exists = exists, page = page)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
    },

    #' @description Close listing file
    close = function() {
      in_buf <- NULL
      tryCatch(
        {
          out_buf <- self$request("close")
          in_buf <- self$invoke(out_buf)
        },
        finally = {
          if (!is.null(in_buf)) {
            self$release_buf(in_buf)
          }
        }
      )
      invisible(self)
    }
  ),

  private = list(
    read_page = function(in_buf) {
      # Read Page structure - need to check Python PageHelper for exact format
      geometry_index <- in_buf$read_long()
      line_count <- in_buf$read_int()
      lines <- character(line_count)
      for (i in seq_len(line_count)) {
        lines[i] <- in_buf$read_string()
      }
      list(geometry_index = geometry_index, lines = lines)
    }
  )
)
