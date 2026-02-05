test_that("SlcError works", {
  error <- SlcError$new("Test error")
  expect_equal(error$reason, "Test error")
  expect_s3_class(error, "SlcError")
})

test_that("InternalError inherits from SlcError", {
  error <- InternalError$new("Internal test error")
  expect_equal(error$reason, "Internal test error")
  expect_s3_class(error, "InternalError")
  expect_s3_class(error, "SlcError")
})

test_that("UserError inherits from SlcError", {
  error <- UserError$new("User test error")
  expect_equal(error$reason, "User test error")
  expect_s3_class(error, "UserError")
  expect_s3_class(error, "SlcError")
})

test_that("Default error messages work", {
  internal_error <- InternalError$new()
  expect_equal(internal_error$reason, "An internal error has occurred.")
  
  user_error <- UserError$new()
  expect_equal(user_error$reason, "An error has occurred.")
})