#' Utility functions for SLC operations
#'
#' @description
#' Utility functions for logging and error handling in SLC operations.
#'
#' @name slc_utils
NULL

#' @rdname slc_utils
#' @param msg Character string with message to log
#' @export
saslog <- function(msg) {
  message(msg)
}

#' @rdname slc_utils
#' @param exc_file Character string with exception file path
#' @param error Error object
#' @export
slc_r_exception <- function(exc_file, error) {
  # Get call stack information
  calls <- sys.calls()
  
  if (length(calls) > 0) {
    # Get the last call for context
    last_call <- calls[[length(calls)]]
    call_text <- deparse(last_call)[1]
    
    # Create error message
    error_msg <- sprintf("%s - %s", class(error)[1], conditionMessage(error))
    message <- sprintf("%s (%s) - %s", error_msg, call_text, error$message)
  } else {
    message <- sprintf("%s - %s", class(error)[1], conditionMessage(error))
  }
  
  # Write to exception file
  writeLines(message, exc_file)
  
  invisible(message)
}