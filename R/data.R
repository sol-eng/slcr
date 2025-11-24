# R/data.R
#' Convert R DataFrame to SLC Dataset
#'
#' @param data R data.frame to convert
#' @param dataset_name Name for the SLC dataset
#' @param connection SLC connection object. If NULL (default), a new connection will be created automatically.
#'
#' @return Invisible NULL
#' @export
#'
#' @examples
#' \dontrun{
#' # Initialize connection
#' conn <- slc_init()
#'
#' # Write R dataframe to SLC
#' write_slc_data(mtcars, "mtcars_sas", conn)
#'
#' # Verify the dataset was created
#' print("Dataset written successfully")
#' }
write_slc_data <- function(data, dataset_name, connection = NULL) {
  if (is.null(connection)) {
    connection <- slc_init()
  }

  work_lib <- connection$get_library('WORK')

  # Convert R data.frame to Python DataFrame
  work_lib$create_dataset_from_dataframe(dataset_name, data)

  message("Currently available work lib datasets: ", work_lib$get_datasets())
  return(connection)
}

#' Read SLC Dataset into R
#'
#' @param dataset_name Name of the SLC dataset
#' @param connection SLC connection object
#'
#' @return R data.frame
#' @export
#' @examples
#' \dontrun{
#' # Initialize connection
#' conn <- slc_init()
#'
#' # First write some data
#' write_slc_data(mtcars, "mtcars_dataset", conn)
#'
#' # Then read it back
#' mtcars_copy <- read_slc_data("mtcars_dataset", conn)
#'
#' # Compare dimensions
#' dim(mtcars)
#' dim(mtcars_copy)
#'
#' # Compare elememt by element
#' mtcars_copy == mtcars
#' }
read_slc_data <- function(dataset_name, connection = NULL) {
  if (is.null(connection)) {
    connection <- slc_init()
  }

  work_lib <- connection$get_library('WORK')

  return(work_lib$open_dataset(dataset_name, "r")$to_data_frame())
}
