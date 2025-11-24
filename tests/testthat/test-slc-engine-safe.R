# File: tests/testthat/test-slc-engine-safe.R

test_that("slc_engine function exists and has correct signature", {
  # Test that the function exists and can be called
  expect_true(exists("slc_engine"))
  expect_type(slc_engine, "closure")
})

test_that("slc_engine handles missing code gracefully", {
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

  # Test with empty options - include required knitr fields
  options <- list(
    code = character(0),
    eval = TRUE,
    echo = TRUE,
    engine = "slc",
    label = "test-chunk"
  )

  # This should not crash
  expect_no_error({
    result <- slc_engine(options)
    expect_s3_class(result, "knit_asis")
  })
})

test_that("slc_engine handles invalid input_data gracefully", {
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

  # Test with non-existent input_data - include required knitr fields
  options <- list(
    code = c("data test; run;"),
    input_data = "nonexistent_data",
    eval = TRUE,
    echo = TRUE,
    engine = "slc",
    label = "test-chunk"
  )

  # Should handle the error gracefully
  expect_no_error({
    result <- slc_engine(options)
    expect_s3_class(result, "knit_asis")
  })
})

test_that("slc_engine returns correct structure", {
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

  # Test basic structure without actually running SLC
  options <- list(
    code = c("/* test comment */"),
    eval = FALSE, # Don't actually evaluate
    echo = TRUE,
    engine = "slc",
    label = "test-chunk"
  )

  result <- slc_engine(options)
  expect_s3_class(result, "knit_asis")
})
