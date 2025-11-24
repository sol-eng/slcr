# R/utils.R
#' Ensure Python Environment is Properly Configured
#'
#' @description
#' Internal utility function that ensures the Python environment is properly
#' set up for SLC integration. This function is automatically called by other
#' slcr functions and typically doesn't need to be called directly by users.
#'
#' @details
#' This function performs several important setup tasks:
#'
#' 1. **Sets default Python path**: If `config.slc.pythonpath` option is not set,
#'    it defaults to `/opt/altair/slc/2026/python` (the standard SLC installation path)
#'
#' 2. **Initializes Python environment**: Calls `setup_python_env()` to ensure
#'    the virtual environment exists and required packages are installed
#'
#' 3. **Configures PYTHONPATH**: Adds the SLC module path to the system PYTHONPATH
#'    environment variable so Python can find the SLC modules
#'
#' ## Configuration Options
#'
#' The function uses the `config.slc.pythonpath` option to locate SLC Python modules:
#'
#' ```r
#' # Set custom SLC Python path before using slcr functions
#' options(config.slc.pythonpath = "/custom/path/to/slc/python")
#'
#' # Check current setting
#' getOption("config.slc.pythonpath")
#' ```
#'
#' ## PYTHONPATH Management
#'
#' The function intelligently manages the PYTHONPATH environment variable:
#' - If PYTHONPATH is empty, sets it to the SLC path
#' - If PYTHONPATH exists but doesn't contain the SLC path, appends it
#' - If SLC path is already in PYTHONPATH, leaves it unchanged
#'
#' @return Invisibly returns `TRUE` on successful completion
#'
#' @keywords internal
#'
#' @examples
#' \dontrun{
#' # This function is called automatically, but you can call it manually:
#' ensure_python_env()
#'
#' # Check the PYTHONPATH after setup
#' Sys.getenv("PYTHONPATH")
#'
#' # Customize SLC path before calling
#' options(config.slc.pythonpath = "/opt/altair/slc/2025/python")
#' ensure_python_env()
#' }
#'
#' # Example of checking configuration
#' if (FALSE) {
#'   # See current Python path setting
#'   current_path <- getOption("config.slc.pythonpath")
#'   if (is.null(current_path)) {
#'     message("Using default SLC path: /opt/altair/slc/2026/python")
#'   } else {
#'     message("Using custom SLC path: ", current_path)
#'   }
#'
#'   # Ensure environment is set up
#'   ensure_python_env()
#'
#'   # Check final PYTHONPATH
#'   message("PYTHONPATH: ", Sys.getenv("PYTHONPATH"))
#' }
ensure_python_env <- function() {
  # Set default Python path if not already configured
  if (is.null(getOption("config.slc.pythonpath"))) {
    options(config.slc.pythonpath = "/opt/altair/slc/2026/python")
  }

  # Setup Python environment if needed
  setup_python_env()

  # Add SLC module path to PYTHONPATH
  slc_path <- getOption("config.slc.pythonpath")
  current_pythonpath <- Sys.getenv("PYTHONPATH")
  if (current_pythonpath == "") {
    Sys.setenv(PYTHONPATH = slc_path)
  } else if (!grepl(slc_path, current_pythonpath)) {
    Sys.setenv(PYTHONPATH = paste(current_pythonpath, slc_path, sep = ":"))
  }

  invisible(TRUE)
}
