#' Dataset Class
#'
#' @description Represents a SAS dataset in SLC
#' @export
Dataset <- R6::R6Class(
  "Dataset",
  private = list(
    dataset_obj = NULL
  ),

  public = list(
    #' @description Create dataset object
    #' @param dataset WpsDataset object
    initialize = function(dataset) {
      private$dataset_obj <- dataset
    },

    #' @description Close the dataset
    close = function() {
      private$dataset_obj$close()
      invisible(self)
    },

    #' @description Get number of observations
    #' @return Integer
    get_nobs = function() {
      private$dataset_obj$get_nobs()
    },

    #' @description Get number of variables
    #' @return Integer
    get_nvars = function() {
      private$dataset_obj$get_nvars()
    },

    #' @description Convert dataset to data frame
    #' @param format Data format ("csv" or "parquet")
    #' @return tibble
    to_dataframe = function(format = "csv") {
      stop(
        "to_dataframe requires session access - use Slc$submit() with PROC EXPORT instead"
      )
    }
  )
)
