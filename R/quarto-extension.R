#' Install SLC Quarto Extension
#'
#' Installs the SLC Quarto extension to the specified directory.
#' This extension provides support for SAS Language Compiler (SLC)
#' code blocks in Quarto documents.
#'
#' @param dest_dir Character. Directory where the extension should be installed.
#'   Defaults to current working directory.
#' @param force Logical. Whether to overwrite existing extension. Defaults to FALSE.
#'
#' @return Invisibly returns the path where the extension was installed.
#' @export
#'
#' @examples
#' \dontrun{
#' # Install extension in current directory
#' install_slc_extension()
#'
#' # Install in specific project directory
#' install_slc_extension("path/to/quarto/project")
#' }
install_slc_extension <- function(dest_dir = ".", force = FALSE) {
  # Get the extension path from the package
  ext_source <- system.file("quarto-ext", "slc", package = "slcr")

  if (ext_source == "") {
    stop(
      "SAS Language Compiler Quarto extension not found in slcr package installation"
    )
  }

  # Create destination path
  dest_path <- file.path(dest_dir, "_extensions", "slc")

  # Check if extension already exists
  if (dir.exists(dest_path) && !force) {
    stop(
      "Extension already exists at ",
      dest_path,
      ". Use force = TRUE to overwrite."
    )
  }

  # Create directory structure
  dir.create(dirname(dest_path), recursive = TRUE, showWarnings = FALSE)

  # Copy extension files
  success <- file.copy(
    ext_source,
    dirname(dest_path),
    recursive = TRUE,
    overwrite = force
  )

  if (!success) {
    stop("Failed to copy extension files")
  }

  message("SAS Language Compiler Quarto extension installed successfully!")
  message("Extension location: ", dest_path)
  message("\nTo use in your Quarto document, add to YAML header:")
  message("filters:")
  message("  - slc")

  invisible(dest_path)
}

#' Check if SLC Quarto Extension is Available
#'
#' Checks whether the SAS Language Compiler Quarto extension is available in the current
#' directory or a specified directory.
#'
#' @param dir Character. Directory to check for the extension.
#'   Defaults to current working directory.
#'
#' @return Logical. TRUE if extension is found, FALSE otherwise.
#' @export
#'
#' @examples
#' # Check if extension is available in current directory
#' has_slc_extension()
#'
#' # Check in specific directory
#' has_slc_extension("path/to/project")
has_slc_extension <- function(dir = ".") {
  ext_path <- file.path(dir, "_extensions", "slc", "_extension.yml")
  file.exists(ext_path)
}
