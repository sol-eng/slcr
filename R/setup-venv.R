#' Setup Python Environment
#'
#' @description
#' Creates a virtual environment and installs required Python packages.
#' Setup Python Environment
#'
#' @description
#' Creates a virtual environment and installs required Python packages.
#' This should be run once after package installation.
#'
#' @param force Logical, whether to force recreation of the environment if it exists
#' @export
setup_python_env <- function(force = FALSE) {
  # Use R's user data directory for package-specific venv
  venv_dir <- file.path(rappdirs::user_data_dir("slcr"), "venvs")

  # If environment exists and we're not forcing recreation, just use it
  if (dir.exists(venv_dir) && !force) {
    message("Using existing Python environment.")
    reticulate::use_python(
      file.path(venv_dir, "bin", "python"),
      required = TRUE
    )
    return(invisible(venv_dir))
  }

  message("Creating Python virtual environment for slcr...")

  # Try to create virtual environment
  tryCatch(
    {
      if (is.null(getOption("config.slc.python"))) {
        options(config.slc.python = Sys.which("python3"))
      }

      reticulate::virtualenv_create(
        envname = venv_dir,
        python = getOption("config.slc.python")
      )

      # Install required packages
      reticulate::virtualenv_install(
        envname = venv_dir,
        packages = c("pandas")
      )

      message("Python environment setup complete.")
    },
    error = function(e) {
      # Fallback: just use system Python
      warning(
        "Failed to create virtual environment. Using system Python instead."
      )
      warning("Error was: ", e$message)

      # Use system Python directly
      reticulate::use_python(Sys.which("python3"), required = TRUE)

      # Check if pandas is available
      if (!reticulate::py_module_available("pandas")) {
        warning(
          "The pandas package is not available in the system Python. Some functionality may be limited."
        )
      }
    }
  )

  reticulate::use_python(paste0(venv_dir, "/bin/python3"))

  invisible(venv_dir)
}
