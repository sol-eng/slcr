#' SLC Engine for Quarto
#'
#' @description
#' Provides support for executing SLC code blocks in Quarto documents.
#' This function is automatically called by knitr when processing SLC code chunks.
#'
#' @param options A list of chunk options from knitr, including:
#'   \describe{
#'     \item{code}{Character vector containing the SLC code to execute}
#'     \item{input_data}{Name of R data.frame to make available in SLC (optional)}
#'     \item{output_data}{Name for capturing SLC output data into R (optional)}
#'     \item{eval}{Whether to evaluate the code (default: TRUE)}
#'     \item{echo}{Whether to show the code (default: TRUE)}
#'     \item{include}{Whether to include output (default: TRUE)}
#'   }
#'
#' @return A knitr engine output object containing the code and results
#'
#' @details
#' This function handles the execution of SLC code within Quarto documents by:
#' \itemize{
#'   \item Initializing SLC connection if needed
#'   \item Transferring input data from R to SLC if specified
#'   \item Executing the SLC code
#'   \item Capturing output and logs
#'   \item Transferring output data from SLC to R if specified
#' }
#'
#' When \code{output_data} is specified, the function assigns the resulting
#' data frame to the global environment using \code{assign()}. This is intentional
#' behavior to make SLC output data available for subsequent R code chunks in
#' Quarto documents.
#'
#' @importFrom knitr engine_output
#' @export
#'
#' @examples
#' \dontrun{
#' # This function is typically called automatically by knitr
#' # when processing SLC code chunks in Quarto documents
#'
#' # Example chunk options that would be passed:
#' options <- list(
#'   code = c("data test;", "  x = 1;", "run;"),
#'   input_data = "mtcars",
#'   output_data = "results",
#'   eval = TRUE,
#'   echo = TRUE
#' )
#'
#' # The engine would be called like this:
#' # slc_engine(options)
#' }
slc_engine <- function(options) {
  # Validate input
  if (!is.list(options)) {
    stop("options must be a list")
  }

  # Handle missing or empty code
  if (is.null(options$code) || length(options$code) == 0) {
    code <- ""
  } else {
    code <- paste(options$code, collapse = "\n")
  }

  output <- character(0)

  # Check if we should actually evaluate the code
  should_eval <- isTRUE(options$eval)

  if (!should_eval || nchar(trimws(code)) == 0) {
    # Don't execute, just return the code
    return(knitr::engine_output(options, code, character(0)))
  }

  tryCatch(
    {
      # Initialize SLC if needed
      ensure_python_env()
      connection <- slc_init()

      # Handle input data if specified
      if (!is.null(options$input_data)) {
        if (!exists(options$input_data, envir = .GlobalEnv)) {
          stop(
            "input_data '",
            options$input_data,
            "' not found in global environment"
          )
        }

        input_data <- get(options$input_data, envir = .GlobalEnv)
        if (!is.data.frame(input_data)) {
          stop("input_data must refer to a data.frame")
        }
        write_slc_data(input_data, options$input_data, connection)
      }

      # Execute the code if present
      if (nchar(trimws(code)) > 0) {
        result <- slc_submit(code, connection)
        log_output <- get_slc_log(connection)

        if (is.list(log_output) && !is.null(log_output$log)) {
          output <- log_output$log
        } else if (is.character(log_output)) {
          output <- log_output
        }
      }

      # Handle output data if specified
      if (!is.null(options$output_data)) {
        tryCatch(
          {
            output_df <- read_slc_data(options$output_data, connection)
            assign(options$output_data, output_df, envir = .GlobalEnv)
          },
          error = function(e) {
            warning(
              "Could not read output_data '",
              options$output_data,
              "': ",
              e$message
            )
          }
        )
      }
    },
    error = function(e) {
      output <- paste("Error:", e$message)
    }
  )

  # Always return a proper knitr output object
  knitr::engine_output(options, code, output)
}
