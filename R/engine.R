# R/engine.R
#' SLC Engine for Quarto
#'
#' @description
#' Provides support for executing SLC code blocks in Quarto documents
#'
#' @importFrom knitr engine_output
#' @export
slc_engine <- function(options) {
  code <- paste(options$code, collapse = "\n")
  output <- character(0)

  tryCatch(
    {
      # Initialize SLC if needed
      ensure_python_env()
      connection <- slc_init()

      # Handle input data if specified
      if (!is.null(options$input_data)) {
        input_data <- get(options$input_data, envir = .GlobalEnv)
        if (!is.data.frame(input_data)) {
          stop("input_data must refer to a data.frame")
        }
        write_slc_data(input_data, options$input_data, connection)
      }

      # Execute the code if present
      if (nchar(code) > 0) {
        result <- slc_submit(code, connection)
        output <- get_slc_log(connection)$log
      }

      # Handle output data if specified
      if (!is.null(options$output_data)) {
        output_df <- read_slc_data(options$output_data, connection)
        assign(options$output_data, output_df, envir = .GlobalEnv)
      }
    },
    error = function(e) {
      output <<- paste("Error:", e$message)
    },
    finally = {
      # Clean up Python resources
      if (exists("connection")) {
        try(reticulate::py_run_string("del connection"), silent = TRUE)
      }
    }
  )

  knitr::engine_output(options, code, output)
}
