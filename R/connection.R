# R/connection.R
#' Initialize SLC Connection
#'
#' @description
#' Creates a connection to Altair SLC using the Python SDK.
#'
#' @return An SLC connection object
#' @export
#'
#' @examples
#' \dontrun{
#' # Initialize a new SLC connection
#' conn <- slc_init()
#'
#' # Check if connection is working
#' class(conn)
#'
#' # The connection can be reused for multiple operations
#' write_slc_data(mtcars, "cars", conn)
#' }
#'
#' # Example without running SLC (for testing)
#' if (FALSE) {
#'   conn <- slc_init()
#'   print("SLC connection established")
#' }
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
#' @param connection SLC connection object. If NULL (default), a new connection will be created automatically.
#'
#' @return Results from SLC execution
#' @export
#'
#' @examples
#' \dontrun{
#' # Initialize connection
#' conn <- slc_init()
#'
#' # Submit basic SLC code
#' slc_submit("data test; x = 1; y = 2; run;", conn)
#'
#' # Submit code with automatic connection
#' slc_submit("proc print data=sashelp.class; run;")
#'
#' # Read and submit the SAS code from file (sas_file)
#' sas_code <- readLines(sas_file)
#'
#' slc_submit(paste(sas_code, collapse = "\n"), conn)
#' }
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
#' @param connection SLC connection object. If NULL (default), a new connection will be created automatically.
#' @param type Character string specifying log type: "all", "log", or "error"
#'
#' @return Log contents as character vector or list
#' @export
#'
#' @examples
#' \dontrun{
#' # Initialize connection and run some code
#' conn <- slc_init()
#' slc_submit("data test; x = 1; run;", conn)
#'
#' # Get all log output
#' logs <- get_slc_log(conn, "all")
#' str(logs)
#'
#' # Get only the log portion
#' log_only <- get_slc_log(conn, "log")
#' cat(log_only, sep = "\n")
#'
#' # Get only error/listing output
#' errors <- get_slc_log(conn, "error")
#'
#' # Using automatic connection
#' slc_submit("proc print data=sashelp.class; run;")
#' recent_logs <- get_slc_log(type = "all")
#' }
#'
#' # Example of log types
#' if (FALSE) {
#'   conn <- slc_init()
#'
#'   # Run code that generates log output
#'   slc_submit("data example; x = 1; y = x * 2; run;", conn)
#'
#'   # Different ways to access logs
#'   all_output <- get_slc_log(conn, "all")      # Both log and listing
#'   log_output <- get_slc_log(conn, "log")      # Just the log
#'   lst_output <- get_slc_log(conn, "error")    # Just the listing
#' }
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
