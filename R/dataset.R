#' SAS Dataset Interface
#'
#' @description
#' The `Dataset` class provides an interface to individual SAS datasets in SLC.
#' It allows you to query dataset properties like the number of observations
#' and variables, and provides methods for dataset operations.
#'
#' @details
#' Dataset objects are typically created by opening existing datasets through
#' a Library object, rather than being constructed directly. The class provides
#' methods to:
#' \itemize{
#'   \item Get dataset dimensions (number of rows and columns)
#'   \item Close the dataset when finished
#'   \item Convert to R data frames (via PROC EXPORT)
#' }
#'
#' @examples
#' \dontrun{
#' # Open a dataset through a library
#' slc <- Slc$new()
#' work_lib <- slc$get_library("WORK")
#'
#' # Create some test data first
#' slc$submit('
#'   data test;
#'     do i = 1 to 100;
#'       x = ranuni(123);
#'       y = i * 2;
#'       output;
#'     end;
#'   run;
#' ')
#'
#' # Open the dataset
#' dataset <- work_lib$open_dataset("test")
#'
#' # Get dimensions
#' nrows <- dataset$get_nobs()    # 100
#' ncols <- dataset$get_nvars()   # 3 (i, x, y)
#'
#' # Close when done
#' dataset$close()
#' }
#'
#' @export
Dataset <- R6::R6Class(
  "Dataset",
  private = list(
    dataset_obj = NULL
  ),

  public = list(
    #' @description Create a new Dataset object
    #' @param dataset A WpsDataset object representing the SAS dataset
    #' @return A new Dataset object
    #' @examples
    #' \dontrun{
    #' # Usually created via Library$open_dataset() rather than directly
    #' dataset <- work_lib$open_dataset("mytable")
    #' }
    initialize = function(dataset) {
      private$dataset_obj <- dataset
    },

    #' @description Close the dataset and free resources
    #' @return Invisible self (for method chaining)
    #' @details
    #' Closes the dataset connection and frees any associated resources.
    #' It's good practice to close datasets when finished with them,
    #' especially in long-running sessions.
    #' @examples
    #' \dontrun{
    #' dataset <- work_lib$open_dataset("mytable")
    #' # ... work with dataset ...
    #' dataset$close()
    #' }
    close = function() {
      private$dataset_obj$close()
      invisible(self)
    },

    #' @description Get the number of observations (rows) in the dataset
    #' @return Integer number of observations
    #' @examples
    #' \dontrun{
    #' dataset <- work_lib$open_dataset("mytable")
    #' nrows <- dataset$get_nobs()
    #' cat("Dataset has", nrows, "observations\n")
    #' }
    get_nobs = function() {
      private$dataset_obj$get_nobs()
    },

    #' @description Get the number of variables (columns) in the dataset
    #' @return Integer number of variables
    #' @examples
    #' \dontrun{
    #' dataset <- work_lib$open_dataset("mytable")
    #' ncols <- dataset$get_nvars()
    #' cat("Dataset has", ncols, "variables\n")
    #' }
    get_nvars = function() {
      private$dataset_obj$get_nvars()
    },

    #' @description Convert dataset to an R data frame
    #' @param format Character string data format ("csv" or "parquet")
    #' @return Data frame (currently not implemented)
    #' @details
    #' This method is not yet fully implemented. Use the Library class
    #' method `get_dataset_as_dataframe()` instead, which uses PROC EXPORT
    #' to convert SAS datasets to R data frames.
    #' @examples
    #' \dontrun{
    #' # Use this instead:
    #' work_lib <- slc$get_library("WORK")
    #' df <- work_lib$get_dataset_as_dataframe("mytable")
    #' }
    to_dataframe = function(format = "csv") {
      stop(
        "to_dataframe requires session access - use Slc$submit() with PROC EXPORT instead"
      )
    }
  )
)
