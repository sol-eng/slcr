#' Library Class
#'
#' @description Represents a SAS library in SLC
#' @export
Library <- R6::R6Class(
  "Library",
  private = list(
    libref_obj = NULL,
    session_obj = NULL
  ),

  public = list(
    #' @description Create library object
    #' @param libref WpsLibref object
    #' @param session WpsSession object (optional, needed for dataframe operations)
    initialize = function(libref, session = NULL) {
      private$libref_obj <- libref
      private$session_obj <- session
    },

    #' @description Get library name
    #' @return String
    get_name = function() {
      private$libref_obj$get_name()
    },

    #' @description Get dataset names in library
    #' @return Character vector
    get_dataset_names = function() {
      private$libref_obj$get_member_names()
    },

    #' @description Open existing dataset
    #' @param name Dataset name
    #' @return Dataset object
    open_dataset = function(name) {
      ds_obj <- private$libref_obj$open_dataset(name, "INPUT")
      Dataset$new(ds_obj)
    },

    #' @description Create new dataset
    #' @param name Dataset name
    #' @return Dataset object
    create_dataset = function(name) {
      ds_obj <- private$libref_obj$create_dataset(name)
      Dataset$new(ds_obj)
    },

    #' @description Create dataset from data frame
    #' @param df Data frame
    #' @param name Dataset name (defaults to data frame name)
    #' @param format Data format ("csv" or "parquet")
    #' @return Invisible self
    create_dataset_from_dataframe = function(
      df,
      name = deparse(substitute(df)),
      format = "csv"
    ) {
      if (is.null(private$session_obj)) {
        stop(
          "create_dataset_from_dataframe requires session access - use Slc$get_library() to get a library with session access"
        )
      }

      temp_file <- tempfile(fileext = paste0(".", format))

      if (format == "csv") {
        readr::write_csv(df, temp_file)
      } else if (format == "parquet") {
        if (!requireNamespace("arrow", quietly = TRUE)) {
          stop("arrow package required for parquet format")
        }
        arrow::write_parquet(df, temp_file)
      } else {
        stop("Unsupported format: ", format)
      }

      libname <- self$get_name()
      code <- sprintf(
        "proc import datafile='%s' out=%s.%s dbms=%s replace; run;",
        temp_file,
        libname,
        name,
        format
      )

      private$session_obj$submit(code)
      invisible(self)
    },

    #' @description Get dataset as data frame
    #' @param name Dataset name
    #' @return Data frame
    get_dataset_as_dataframe = function(name) {
      # Use PROC EXPORT to write to a temporary CSV file, then read it into R

      temp_file <- tempfile(fileext = ".csv")

      # Get the library name from the libref
      lib_name <- private$libref_obj$get_name()

      # Export the dataset to CSV
      sas_code <- sprintf(
        'proc export data=%s.%s outfile="%s" dbms=csv replace; run;',
        lib_name,
        name,
        temp_file
      )

      # Submit via session
      private$session_obj$submit(sas_code)

      # Read the CSV into R
      if (file.exists(temp_file)) {
        df <- utils::read.csv(temp_file, stringsAsFactors = FALSE)
        unlink(temp_file)
        df
      } else {
        stop(sprintf("Failed to export dataset %s.%s", lib_name, name))
      }
    }
  )
)
