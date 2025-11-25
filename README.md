# slcr: R Interface to Altair SLC


## Overview

The `slcr` package provides an R interface to Altair SLC, enabling users
to execute SLC code and transfer data between R and SLC environments.
This document outlines the installation, configuration, and usage of the
package.

## Installation

You can install the development version of slcr from GitHub:

``` r
# install.packages("devtools")
devtools::install_github("sol-eng/slcr")
```

## Prerequisites

- R (\>= 4.0.0)
- Altair SLC (\>= 2026)
- Python module `slc` from Altair SLC installation

## Configuration

Before using the package, you need to configure the Python path where
Altair SLC is installed. Let’s demonstrate the configuration options:

``` r
# Method 1: Before loading the package
options(slc.pythonpath = "/path/to/altair/slc/python")
library(slcr)

# Method 2: In your .Rprofile
# Add this line to your .Rprofile file:
options(slc.pythonpath = "/path/to/altair/slc/python")
```

The default path is `/opt/altair/slc/2026/python` if no custom path is
specified.

## Basic Usage

Let’s walk through some basic examples of using the package:

``` r
# Load the package
library(slcr)

# Initialize a connection
conn <- slc_init()

# Execute SLC code
slc_submit("proc print data=sashelp.class;", conn)
```

### Data Transfer Examples

Here’s how to transfer data between R and SLC:

``` r
# Create sample data
df <- data.frame(
  x = 1:10,
  y = letters[1:10],
  z = rnorm(10)
)

# Write R data frame to SLC
write_slc_data(df, "mydata", conn)

# Read SLC dataset back into R
result <- read_slc_data("mydata", conn)

# View the results
head(result)
```

## Core Functions

The package provides four main functions:

1.  `slc_init()`: Initialize SLC connection
    - Returns a connection object used by other functions
    - Automatically configures Python environment
2.  `slc_submit()`: Execute SLC code
    - Accepts SLC code as a character string
    - Returns execution results
3.  `write_slc_data()`: Write R data frames to SLC
    - Converts R data frames to SLC datasets
    - Handles data type conversion automatically
4.  `read_slc_data()`: Read SLC datasets into R
    - Converts SLC datasets to R data frames
    - Preserves data types where possible

## Error Handling

The package includes robust error handling. Here’s an example:

``` r
# Example with error handling
tryCatch(
  {
    conn <- slc_init()
    slc_submit("proc print data=nonexistent;", conn)
  },
  error = function(e) {
    message("An error occurred: ", e$message)
  }
)
```

## Contributing

Contributions to the package are welcome! Here’s how you can contribute:

1.  Report issues on GitHub
2.  Submit pull requests
3.  Suggest new features
4.  Improve documentation

## License

This package is released under the MIT License.

## Session Info

``` r
sessionInfo()
```

    R version 4.5.1 (2025-06-13)
    Platform: x86_64-pc-linux-gnu
    Running under: Rocky Linux 9.3 (Blue Onyx)

    Matrix products: default
    BLAS/LAPACK: FlexiBLAS OPENBLAS-OPENMP;  LAPACK version 3.9.0

    locale:
     [1] LC_CTYPE=C.UTF-8       LC_NUMERIC=C           LC_TIME=C.UTF-8       
     [4] LC_COLLATE=C.UTF-8     LC_MONETARY=C.UTF-8    LC_MESSAGES=C.UTF-8   
     [7] LC_PAPER=C.UTF-8       LC_NAME=C              LC_ADDRESS=C          
    [10] LC_TELEPHONE=C         LC_MEASUREMENT=C.UTF-8 LC_IDENTIFICATION=C   

    time zone: UTC
    tzcode source: system (glibc)

    attached base packages:
    [1] stats     graphics  grDevices utils     datasets  methods   base     

    loaded via a namespace (and not attached):
     [1] compiler_4.5.1    fastmap_1.2.0     cli_3.6.5         tools_4.5.1      
     [5] htmltools_0.5.8.1 yaml_2.3.10       rmarkdown_2.29    knitr_1.50       
     [9] jsonlite_2.0.0    xfun_0.54         digest_0.6.37     rlang_1.1.6      
    [13] evaluate_1.0.5   
