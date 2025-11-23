# File: tests/testthat/test-quarto-integration.R

test_that("slc_resource_path returns correct path", {
  path <- slc_resource_path("slc-quarto.html")
  expect_true(file.exists(path))
  expect_match(path, "resources/slc-quarto.html$")
})

test_that("slc_quarto_resources returns HTML content", {
  resources <- slc_quarto_resources()
  expect_s3_class(resources, "html")
  html_str <- as.character(resources)
  expect_match(html_str, "<style>")
  expect_match(html_str, "<script>")
  expect_match(html_str, "slc-output-collapsible")
})

test_that("is_quarto_context detects Quarto environment", {
  # Test when not in Quarto context
  expect_false(is_quarto_context())

  # Mock Quarto environment
  withr::with_envvar(
    new = c("QUARTO_PROJECT_DIR" = tempdir()),
    code = expect_true(is_quarto_context())
  )
})
