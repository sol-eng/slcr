#' SLC Engine for Quarto
#'
#' @description
#' Provides support for executing SLC code blocks in Quarto documents.
#' This function is automatically called by knitr when processing SLC code chunks.
#'
#' @param options A list of chunk options from knitr, including:
#'   \describe{
#'     \item{code}{Character vector containing the SLC code to execute}
#'     \item{input_data}{Name(s) of R data.frame(s) to make available in SLC. Can be a single name or comma-separated names (optional)}
#'     \item{output_data}{Name(s) for capturing SLC output data into R. Can be a single name or comma-separated names (optional)}
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
#' Multiple datasets can be specified using comma-separated names:
#' \itemize{
#'   \item \code{input_data="df1,df2,df3"} - transfers multiple R data.frames to SLC
#'   \item \code{output_data="result1,result2"} - captures multiple datasets from SLC to R
#' }
#'
#' @section Global Environment Assignment:
#' When \code{output_data} is specified, this function intentionally assigns
#' the resulting dataset(s) to the global environment using \code{assign(..., envir = knitr::knit_global())}.
#' This is the expected behavior to make SLC output data available for subsequent
#' R code chunks in the same Quarto document.
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
#' # Multiple datasets example:
#' options <- list(
#'   code = c("data combined;", "  set df1 df2;", "run;"),
#'   input_data = "df1,df2",
#'   output_data = "combined,summary",
#'   eval = TRUE,
#'   echo = TRUE
#' )
#'
#' # The engine would be called like this:
#' # slc_engine(options)
#' }
slc_engine <- function(options) {
  # Validate that options is a list
  if (!is.list(options)) {
    stop("options must be a list")
  }

  code <- paste(options$code, collapse = "\n")
  output <- character(0)
  connection <- NULL

  # Skip execution if eval is FALSE
  if (isFALSE(options$eval)) {
    return(knitr::engine_output(options, code, output))
  }

  tryCatch(
    {
      # Initialize SLC if needed
      connection <- Slc$new()
      work_lib <- connection$get_library("WORK")

      # Handle input data if specified
      input_names <- parse_multiple_names(options$input_data)
      if (length(input_names) > 0) {
        for (input_name in input_names) {
          if (!exists(input_name, envir = knitr::knit_global())) {
            stop(
              "Object '",
              input_name,
              "' not found in global environment"
            )
          }

          input_data <- get(input_name, envir = knitr::knit_global())
          if (!is.data.frame(input_data)) {
            stop("input_data '", input_name, "' must refer to a data.frame")
          }
          work_lib$create_dataset_from_dataframe(input_data, name = input_name)
        }
      }

      # Execute the code if present
      if (nchar(code) > 0) {
        result <- connection$submit(code)
        log_output <- connection$get_log()
        if (is.list(log_output) && "log" %in% names(log_output)) {
          output <- log_output$log
        } else {
          output <- as.character(log_output)
        }
      }

      # Handle output data if specified
      output_names <- parse_multiple_names(options$output_data)
      if (length(output_names) > 0) {
        for (output_name in output_names) {
          output_df <- work_lib$get_dataset_as_dataframe(output_name)
          # Intentional assignment to global environment for Quarto workflow
          assign(output_name, output_df, envir = knitr::knit_global())
        }
      }
    },
    error = function(e) {
      stop(e$message)
    }
  )

  knitr::engine_output(options, code, output)
}


#' Parse comma-separated names from chunk options
#'
#' @param names_string A string containing comma-separated names, or NULL
#' @return A character vector of trimmed names, or character(0) if input is NULL/empty
#' @keywords internal
parse_multiple_names <- function(names_string) {
  if (is.null(names_string) || names_string == "") {
    return(character(0))
  }
  trimws(strsplit(names_string, ",")[[1]])
}
