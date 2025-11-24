#' Get path to SLC Quarto resources
#' @param file The resource file name
#' @return Path to the resource file
#' @export
slc_resource_path <- function(file) {
  system.file("resources", file, package = "slcr")
}

#' Include SLC Quarto resources in document
#'
#' This function includes CSS and JavaScript resources to enhance SLC code chunks
#' in Quarto documents. It extracts the same functionality from the SLC Quarto
#' extension's Lua filter to ensure consistency.
#'
#' @section Quarto Integration:
#' There are two ways to use SLC with Quarto:
#'
#' 1. Using the `slc_quarto_resources()` function:
#'    ```r
#'    library(slcr)
#'    slc_quarto_resources()
#'    ```
#'
#' 2. Installing the Quarto extension (recommended):
#'    ```bash
#'    quarto add michaelmayer2/slc-quarto-ext
#'    ```
#'    Then add `filters: - slc` to your document YAML header.
#'
#' Both approaches provide identical functionality.
#'
#' @return HTML content for SLC styling and collapsible functionality
#' @export
slc_quarto_resources <- function() {
  html_path <- system.file("resources", "slc-resources.html", package = "slcr")

  if (!file.exists(html_path)) {
    warning(
      "SLC Quarto resources not found. Make sure slcr package is properly installed."
    )
    return(htmltools::HTML(""))
  }

  # Read the HTML content
  html_content <- paste(readLines(html_path, warn = FALSE), collapse = "\n")

  # Return raw HTML that will be included directly
  return(htmltools::HTML(html_content))
}

#' Setup SLC for Quarto (called automatically when library is loaded)
#' @export
setup_slc_quarto <- function() {
  # Register the knitr engine if not already registered
  if (is.null(knitr::knit_engines$get("slc"))) {
    knitr::knit_engines$set(slc = slc_engine)
  }

  # Auto-include resources if in a Quarto context
  if (is_quarto_context()) {
    cat(as.character(slc_quarto_resources()))
  }
}

#' Check if we're in a Quarto rendering context
#' @return Logical indicating if in Quarto context
is_quarto_context <- function() {
  !is.null(knitr::opts_knit$get("rmarkdown.pandoc.to")) ||
    Sys.getenv("QUARTO_PROJECT_DIR") != ""
}
