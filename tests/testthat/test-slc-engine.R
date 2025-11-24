# File: tests/testthat/test-slc-engine.R

test_that("slc_engine validates input options", {
  # Test that non-list input throws error
  expect_error(
    slc_engine("not a list"),
    "options must be a list"
  )
})

test_that("slc_engine handles eval=FALSE correctly", {
  # Mock knitr::engine_output to avoid dependency issues
  local_mocked_bindings(
    engine_output = function(options, code, output) {
      structure(
        list(options = options, code = code, output = output),
        class = "knit_asis"
      )
    },
    .package = "knitr"
  )

  options <- list(
    code = c("data test;", "x = 1;", "run;"),
    eval = FALSE,
    echo = TRUE,
    engine = "slc",
    label = "test-chunk",
    fig.path = "figure/",
    cache.path = "cache/",
    label = "test-chunk",
    fig.path = "figure/",
    cache.path = "cache/",
    label = "test-chunk",
    fig.path = "figure/",
    cache.path = "cache/",
    label = "test-chunk",
    fig.path = "figure/",
    cache.path = "cache/"
  )

  result <- slc_engine(options)
  expect_s3_class(result, "knit_asis")
})

test_that("slc_engine handles empty code with eval=FALSE", {
  # Mock knitr::engine_output to avoid dependency issues
  local_mocked_bindings(
    engine_output = function(options, code, output) {
      structure(
        list(options = options, code = code, output = output),
        class = "knit_asis"
      )
    },
    .package = "knitr"
  )

  options <- list(
    code = character(0),
    eval = FALSE,
    echo = TRUE,
    engine = "slc"
  )

  expect_no_error({
    result <- slc_engine(options)
    expect_s3_class(result, "knit_asis")
  })
})

test_that("slc_engine handles NULL code with eval=FALSE", {
  # Mock knitr::engine_output to avoid dependency issues
  local_mocked_bindings(
    engine_output = function(options, code, output) {
      structure(
        list(options = options, code = code, output = output),
        class = "knit_asis"
      )
    },
    .package = "knitr"
  )

  options <- list(
    code = NULL,
    eval = FALSE,
    echo = TRUE,
    engine = "slc"
  )

  expect_no_error({
    result <- slc_engine(options)
    expect_s3_class(result, "knit_asis")
  })
})

test_that("slc_engine handles whitespace-only code with eval=FALSE", {
  # Mock knitr::engine_output to avoid dependency issues
  local_mocked_bindings(
    engine_output = function(options, code, output) {
      structure(
        list(options = options, code = code, output = output),
        class = "knit_asis"
      )
    },
    .package = "knitr"
  )

  options <- list(
    code = c("   ", "\t", "\n"),
    eval = FALSE,
    echo = TRUE,
    engine = "slc"
  )

  expect_no_error({
    result <- slc_engine(options)
    expect_s3_class(result, "knit_asis")
  })
})
