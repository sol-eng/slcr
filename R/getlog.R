#' Get SLC Log Contents
#'
#' @description
#' Retrieves the contents of the SLC log file from the most recent SLC submission
#'
#' @param connection SLC connection object
#' @param type Character string specifying log type: "log" for main log,
#'             "error" for error log, or "all" for both (default)
#'
#' @return A character vector containing the log contents, or a list of logs if type="all"
#' @export
#'
#' @examples
#' \dontrun{
#' # Initialize connection
#' conn <- slc_init()
#'
#' # Run some SLC code
#' slc_submit("proc print data=sashelp.class;", conn)
#'
#' # Get all logs
#' logs <- get_slc_log(conn)
#' str(logs)
#'
#' # Get only the main log
#' main_log <- get_slc_log(conn, type = "log")
#' cat(main_log)
#'
#' # Get only the listing output
#' error_log <- get_slc_log(conn, type = "lst")
#' cat(error_log)
#'
#' # Can also be used without explicit connection
#' logs <- get_slc_log(type = "all")
#' }
get_slc_log <- function(connection = NULL, type = "all") {
  if (is.null(connection)) {
    connection <- slc_init()
  }

  type <- match.arg(type, c("all", "log", "lst"))

  # Load reticulate package
  if (!requireNamespace("reticulate", quietly = TRUE)) {
    stop("Package 'reticulate' is required")
  }

  # Convert Python generators to R vectors
  if (type == "all") {
    list(
      log = reticulate::iterate(connection$getLog(), simplify = TRUE),
      lst = reticulate::iterate(connection$getListingOutput(), simplify = TRUE)
    )
  } else if (type == "log") {
    list(reticulate::iterate(connection$getLog(), simplify = TRUE))
  } else {
    list(reticulate::iterate(connection$getListingOutput(), simplify = TRUE))
  }
}
