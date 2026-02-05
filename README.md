# slcR

R interface to Altair SLC (Statistical Language Compiler).

## Installation

You can install the development version of slcR from GitHub with:

``` r
# install.packages("devtools")
devtools::install_github("sol-eng/slcr")
```

## Example

This is a basic example which shows you how to solve a common problem:

``` r
library(slcR)

# Create SLC connection
slc <- Slc$new()

# Get the WORK library
work_lib <- slc$get_library("WORK")

# Submit SAS code
slc$submit("data test; x = 1; run;")

# Clean up
slc$shutdown()
```