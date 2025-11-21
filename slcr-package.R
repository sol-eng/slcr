#' @keywords internal
"_PACKAGE"

#' SLC Interface for R
#'
#' @description
#' The slcr package provides an R interface to Altair SLC, enabling users to
#' execute SLC code and transfer data between R and SLC environments.
#'
#' @section Configuration:
#' Before using the package, you may need to configure the Python path where
#' Altair SLC is installed. There are two ways to set this:
#'
#' 1. Before loading the package:
#'
#' ```r
#' options(slc.pythonpath = "/path/to/altair/slc/python")
#' library(slcr)
#' ```
#'
#' 2. In your .Rprofile:
#'
#' ```r
#' options(slc.pythonpath = "/path/to/altair/slc/python")
#' ```
#'
#' The default path is `/opt/altair/slc/2026/python`.
#'
#' @section Basic Usage:
#' ```r
#' # Initialize SLC connection
#' conn <- slc_init()
#'
#' # Submit SLC code
#' slc_submit("proc print data=sashelp.class;", conn)
#'
#' # Transfer data from R to SLC
#' df <- data.frame(x = 1:10, y = letters[1:10])
#' write_slc_data(df, "mydata", conn)
#'
#' # Read SLC dataset into R
#' result <- read_slc_data("mydata", conn)
#' ```
#'
#' @seealso
#' * [slc_init()] for initializing a connection
#' * [slc_submit()] for executing SLC code
#' * [write_slc_data()] for writing R data frames to SLC
#' * [read_slc_data()] for reading SLC datasets into R
#'
#' @importFrom reticulate import configure_environment py_to_r r_to_py
#' @name slcr-package
#' @aliases slcr
NULL
