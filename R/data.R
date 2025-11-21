# R/data.R
#' Convert R DataFrame to SLC Dataset
#'
#' @param data R data.frame to convert
#' @param dataset_name Name for the SLC dataset
#' @param connection SLC connection object
#'
#' @return Invisible NULL
#' @export
#'
#' @examples
#' \dontrun{
#' # Initialize connection
#' conn <- slc_init()
#'
#' # Write R dataframe to SAS
#' write_slc_data(mtcars,"mtcars_sas",conn)
#'
#' # Read SAS dataframe back into R
#' mtcars_new <- read_slc_data("mtcars_sas",conn)
#'
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
read_slc_data <- function(dataset_name, connection = NULL) {
  if (is.null(connection)) {
    connection <- slc_init()
  }

  work_lib <- connection$get_library('WORK')

  return(work_lib$open_dataset(dataset_name, "r")$to_data_frame())
}
