# R/zzz.R
.onLoad <- function(libname, pkgname) {
  # Set default SLC Python module path if not already configured
  if (is.null(getOption("config.slc.pythonpath"))) {
    options(config.slc.pythonpath = "/opt/altair/slc/2026/python")
  }

  # Add SLC module path to PYTHONPATH
  slc_path <- getOption("config.slc.pythonpath")
  current_pythonpath <- Sys.getenv("PYTHONPATH")
  if (current_pythonpath == "") {
    Sys.setenv(PYTHONPATH = slc_path)
  } else if (!grepl(slc_path, current_pythonpath)) {
    Sys.setenv(PYTHONPATH = paste(current_pythonpath, slc_path, sep = ":"))
  }

  # Register the SLC engine with knitr
  knitr::knit_engines$set(slc = slc_engine)
}

.onLoad <- function(libname, pkgname) {
  # Register SLC engine
  knitr::knit_engines$set(slc = slc_engine)
}

.onAttach <- function(libname, pkgname) {
  # Setup Quarto integration when package is attached
  if (interactive() && is_quarto_context()) {
    setup_slc_quarto()
  }
}
