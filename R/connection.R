# R/connection.R
#' Initialize SLC Connection
#'
#' @description
#' Creates a connection to Altair SLC using the Python SDK.
#'
#' @return An SLC connection object
#' @export
slc_init <- function() {
  ensure_python_env()
  slc <- reticulate::import("slc.slc")
  # Return the module instead of trying to call init()

  connection <- slc$Slc()

  return(connection)
}

#' Submit SLC Code
#'
#' @param code Character string containing SLC code
#' @param connection SLC connection object
#'
#' @return Results from SLC execution
#' @export
slc_submit <- function(code, connection = NULL) {
  ensure_python_env()

  if (is.null(connection)) {
    message("No connection found, triggering a new session")
    connection <- slc_init()
  }

  connection$submit(text = code)

  return(connection)
}

#' Get SLC Log Contents
#'
#' @param connection SLC connection object
#' @param type Character string specifying log type
#'
#' @return Log contents
#' @export
get_slc_log <- function(connection = NULL, type = "all") {
  ensure_python_env()

  if (is.null(connection)) {
    connection <- slc_init()
  }

  type <- match.arg(type, c("all", "log", "error"))

  # Convert Python generators to R vectors
  if (type == "all") {
    list(
      log = reticulate::iterate(connection$getLog(), simplify = TRUE),
      lst = reticulate::iterate(connection$getListingOutput(), simplify = TRUE)
    )
  } else if (type == "log") {
    reticulate::iterate(connection$getLog(), simplify = TRUE)
  } else {
    reticulate::iterate(connection$getListingOutput(), simplify = TRUE)
  }
}
