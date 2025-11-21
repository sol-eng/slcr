.onLoad <- function(libname, pkgname) {
  knitr::knit_engines$set(slc = slc_engine)
  options(quarto.engine.slc = "slc")
}
