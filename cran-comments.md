## R CMD check results

0 errors ✔ | 1 warning ✖ | 1 note ✖

* This is a new release.

## Test environments

* local R installation, R 4.5.1
* GitHub Actions (ubuntu-latest): R-release, R-devel
* GitHub Actions (windows-latest): R-release
* GitHub Actions (macOS-latest): R-release

## R CMD check results

There were no ERRORs.

There was 1 WARNING:
* 'qpdf' is needed for checks on size reduction of PDFs
  
  This is a system dependency warning that does not affect package functionality.

There was 1 NOTE:
* Found the following assignments to the global environment:
  File 'slcr/R/engine.R': assign(options$output_data, output_df, envir = .GlobalEnv)
  
  This assignment to the global environment is intentional and necessary for knitr engine functionality. The slcr package provides a knitr engine for SLC (SAS Language Compiler) code chunks in Quarto documents. When the `output_data` option is specified, the engine must assign the resulting data frame to the global environment to make SLC output data accessible in subsequent R code chunks within the same document. This is the expected and required behavior for document engines that need to share data between code chunks.

## Downstream dependencies

There are currently no downstream dependencies for this package.