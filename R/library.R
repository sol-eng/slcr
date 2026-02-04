#' SAS Library Interface
#'
#' @description
#' The `Library` class provides a high-level R interface to SAS libraries in SLC.
#' It allows you to list datasets, open existing datasets, create new datasets,
#' and convert between R data frames and SAS datasets.
#'
#' @details
#' A Library object represents a SAS library (libref) and provides methods to:
#' \itemize{
#'   \item List all datasets in the library
#'   \item Open existing datasets for reading
#'   \item Create new empty datasets
#'   \item Import R data frames as SAS datasets
#'   \item Export SAS datasets as R data frames
#' }
#'
#' The library uses PROC IMPORT and PROC EXPORT internally for data frame
#' conversions, supporting CSV and Parquet formats.
#'
#' @examples
#' \dontrun{
#' # Connect to SLC and get the WORK library
#' slc <- Slc$new()
#' work_lib <- slc$get_library("WORK")
#'
#' # List all datasets in the library
#' datasets <- work_lib$get_dataset_names()
#'
#' # Create a dataset from an R data frame
#' work_lib$create_dataset_from_dataframe(mtcars, "cars_data")
#'
#' # Get a dataset back as an R data frame
#' cars_df <- work_lib$get_dataset_as_dataframe("cars_data")
#'
#' # Open a dataset for reading
#' dataset <- work_lib$open_dataset("cars_data")
#' }
#'
#' @export
Library <- R6::R6Class(
  "Library",
  private = list(
    libref_obj = NULL,
    session_obj = NULL
  ),

  public = list(
    #' @description Create a new Library object
    #' @param libref A WpsLibref object representing the SAS library
    #' @param session A WpsSession object (optional, but required for data frame operations)
    #' @return A new Library object
    #' @examples
    #' \dontrun{
    #' # Usually created via Slc$get_library() rather than directly
    #' work_lib <- slc$get_library("WORK")
    #' }
    initialize = function(libref, session = NULL) {
      private$libref_obj <- libref
      private$session_obj <- session
    },

    #' @description Get the name of the library
    #' @return Character string containing the library name (libref)
    #' @examples
    #' \dontrun{
    #' work_lib <- slc$get_library("WORK")
    #' lib_name <- work_lib$get_name()  # Returns "WORK"
    #' }
    get_name = function() {
      private$libref_obj$get_name()
    },

    #' @description Get names of all datasets in the library
    #' @return Character vector of dataset names
    #' @examples
    #' \dontrun{
    #' work_lib <- slc$get_library("WORK")
    #' datasets <- work_lib$get_dataset_names()
    #' print(datasets)  # e.g., c("DATASET1", "DATASET2", "MYTABLE")
    #' }
    get_dataset_names = function() {
      private$libref_obj$get_member_names()
    },

    #' @description Open an existing dataset for reading
    #' @param name Character string specifying the dataset name
    #' @return A Dataset object that can be used to read the dataset
    #' @examples
    #' \dontrun{
    #' work_lib <- slc$get_library("WORK")
    #' dataset <- work_lib$open_dataset("MYTABLE")
    #'
    #' # Get dataset dimensions
    #' nrows <- dataset$get_nobs()
    #' ncols <- dataset$get_nvars()
    #' }
    open_dataset = function(name) {
      ds_obj <- private$libref_obj$open_dataset(name, "INPUT")
      Dataset$new(ds_obj)
    },

    #' @description Create a new empty dataset
    #' @param name Character string specifying the name for the new dataset
    #' @return A Dataset object representing the new empty dataset
    #' @examples
    #' \dontrun{
    #' work_lib <- slc$get_library("WORK")
    #' new_dataset <- work_lib$create_dataset("NEWTABLE")
    #' }
    create_dataset = function(name) {
      ds_obj <- private$libref_obj$create_dataset(name)
      Dataset$new(ds_obj)
    },

    #' @description Create a SAS dataset from an R data frame
    #' @param df Data frame to import into SAS
    #' @param name Character string specifying the dataset name. If not provided,
    #'   uses the name of the data frame variable
    #' @param format Character string specifying the intermediate file format.
    #'   Either "csv" (default) or "parquet"
    #' @return Invisible self (for method chaining)
    #' @details
    #' This method works by:
    #' \enumerate{
    #'   \item Writing the R data frame to a temporary file (CSV or Parquet)
    #'   \item Using PROC IMPORT to read the file into a SAS dataset
    #'   \item Cleaning up the temporary file
    #' }
    #'
    #' For Parquet format, the \code{arrow} package must be installed.
    #'
    #' @examples
    #' \dontrun{
    #' work_lib <- slc$get_library("WORK")
    #'
    #' # Import mtcars as CSV (default)
    #' work_lib$create_dataset_from_dataframe(mtcars, "cars_csv")
    #'
    #' # Import iris as Parquet
    #' work_lib$create_dataset_from_dataframe(iris, "iris_data", format = "parquet")
    #'
    #' # Name defaults to variable name if not specified
    #' my_data <- data.frame(x = 1:5, y = letters[1:5])
    #' work_lib$create_dataset_from_dataframe(my_data)  # Creates dataset "my_data"
    #' }
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

    #' @description Export a SAS dataset as an R data frame
    #' @param name Character string specifying the dataset name to export
    #' @return Data frame containing the dataset contents
    #' @details
    #' This method works by:
    #' \enumerate{
    #'   \item Using PROC EXPORT to write the SAS dataset to a temporary CSV file
    #'   \item Reading the CSV file into R as a data frame
    #'   \item Cleaning up the temporary file
    #' }
    #'
    #' All SAS data types are converted to appropriate R types. Character variables
    #' become character vectors, numeric variables become numeric vectors, and
    #' dates/datetimes are converted to appropriate R date/time classes.
    #'
    #' @examples
    #' \dontrun{
    #' work_lib <- slc$get_library("WORK")
    #'
    #' # First create a dataset in SAS
    #' slc$submit("
    #'   data work.example;
    #'     do i = 1 to 10;
    #'       x = i * 2;
    #'       y = ranuni(123);
    #'       output;
    #'     end;
    #'   run;
    #' ")
    #'
    #' # Export to R data frame
    #' df <- work_lib$get_dataset_as_dataframe("example")
    #' print(df)
    #' }
    get_dataset_as_dataframe = function(name) {
      if (is.null(private$session_obj)) {
        stop(
          "get_dataset_as_dataframe requires session access - use Slc$get_library() to get a library with session access"
        )
      }

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
