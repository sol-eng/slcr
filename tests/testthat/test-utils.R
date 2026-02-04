test_that("saslog function works", {
  expect_message(saslog("test message"), "test message")
})

test_that("slc_r_exception creates error file", {
  temp_file <- tempfile()
  error <- simpleError("Test error")
  
  slc_r_exception(temp_file, error)
  
  expect_true(file.exists(temp_file))
  content <- readLines(temp_file)
  expect_true(length(content) > 0)
  expect_true(grepl("simpleError", content[1]))
  
  unlink(temp_file)
})