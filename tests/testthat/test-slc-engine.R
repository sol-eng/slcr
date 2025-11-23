# File: tests/testthat/test-slc-engine.R

test_that("slc_engine processes code correctly", {
  skip_if_not_installed("reticulate")
  skip_if_not(reticulate::py_module_available("slc"))

  # Simple test with minimal SLC code
  result <- slc_engine("data _null_; put 'test'; run;", list())
  expect_type(result, "character")
})
