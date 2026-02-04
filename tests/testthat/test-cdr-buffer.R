test_that("CdrBuffer can be created", {
  # Create a minimal ORB-like object for testing
  mock_orb <- list()
  buffer <- CdrBuffer$new(mock_orb, initial_capacity = 1024L)

  expect_s3_class(buffer, "CdrBuffer")
  expect_equal(buffer$capacity(), 1024L)
  expect_equal(buffer$position(), 0L)
  expect_equal(buffer$limit(), 1024L)
})

test_that("CdrBuffer write and read byte operations work", {
  mock_orb <- list()
  buffer <- CdrBuffer$new(mock_orb)

  # Write some bytes
  buffer$write_byte(0x42)
  buffer$write_byte(0xFF)
  buffer$write_byte(0x00)

  expect_equal(buffer$position(), 3L)

  # Flip to read mode
  buffer$flip()
  expect_equal(buffer$position(), 0L)
  expect_equal(buffer$limit(), 3L)

  # Read bytes back
  expect_equal(buffer$read_byte(), 0x42)
  expect_equal(buffer$read_byte(), 0xFF)
  expect_equal(buffer$read_byte(), 0x00)
  expect_equal(buffer$position(), 3L)
})

test_that("CdrBuffer write and read integer operations work", {
  mock_orb <- list()
  buffer <- CdrBuffer$new(mock_orb)

  # Write integers
  buffer$write_int(42L)
  buffer$write_int(-100L)
  buffer$write_int(0L)

  # Flip to read mode
  buffer$flip()

  # Read integers back
  expect_equal(buffer$read_int(), 42L)
  expect_equal(buffer$read_int(), -100L)
  expect_equal(buffer$read_int(), 0L)
})

test_that("CdrBuffer write and read string operations work", {
  mock_orb <- list()
  buffer <- CdrBuffer$new(mock_orb)

  # Write strings
  buffer$write_string("Hello")
  buffer$write_string("World")
  buffer$write_string("")

  # Flip to read mode
  buffer$flip()

  # Read strings back
  expect_equal(buffer$read_string(), "Hello")
  expect_equal(buffer$read_string(), "World")
  expect_equal(buffer$read_string(), "")
})

test_that("CdrBuffer flip and clear operations work", {
  mock_orb <- list()
  buffer <- CdrBuffer$new(mock_orb, initial_capacity = 100L)

  # Write some data
  buffer$write_int(123L)
  buffer$write_string("test")

  # Check position advanced
  pos_after_write <- buffer$position()
  expect_gt(pos_after_write, 0L)

  # Flip should set limit to position and reset position
  buffer$flip()
  expect_equal(buffer$position(), 0L)
  expect_equal(buffer$limit(), pos_after_write)

  # Clear should reset everything
  buffer$clear()
  expect_equal(buffer$position(), 0L)
  expect_equal(buffer$limit(), 100L)
})

test_that("CdrBuffer capacity expansion works", {
  mock_orb <- list()
  buffer <- CdrBuffer$new(mock_orb, initial_capacity = 16L)

  initial_cap <- buffer$capacity()

  # Write more data than initial capacity
  for (i in 1:20) {
    buffer$write_int(i)
  }

  # Capacity should have expanded
  expect_gt(buffer$capacity(), initial_cap)

  # Data should be readable
  buffer$flip()
  for (i in 1:20) {
    expect_equal(buffer$read_int(), i)
  }
})

test_that("CdrBuffer read beyond limit fails", {
  mock_orb <- list()
  buffer <- CdrBuffer$new(mock_orb)

  buffer$write_int(42L)
  buffer$flip()

  # Read the integer successfully
  expect_equal(buffer$read_int(), 42L)

  # Try to read beyond limit should fail
  expect_error(buffer$read_int(), "bytes remain")
})

test_that("CdrBuffer write and read boolean operations work", {
  mock_orb <- list()
  buffer <- CdrBuffer$new(mock_orb)

  # Write booleans
  buffer$write_boolean(TRUE)
  buffer$write_boolean(FALSE)
  buffer$write_boolean(TRUE)

  # Flip to read mode
  buffer$flip()

  # Read booleans back
  expect_equal(buffer$read_boolean(), TRUE)
  expect_equal(buffer$read_boolean(), FALSE)
  expect_equal(buffer$read_boolean(), TRUE)
})

test_that("CdrBuffer remaining() works correctly", {
  mock_orb <- list()
  buffer <- CdrBuffer$new(mock_orb, initial_capacity = 100L)

  # Initially, remaining should equal limit (capacity)
  expect_equal(buffer$remaining(), 100L)

  # After writing, remaining should decrease
  buffer$write_int(42L)
  expect_lt(buffer$remaining(), 100L)

  # After flip, remaining should be the amount written
  buffer$flip()
  expect_equal(buffer$remaining(), 4L) # 4 bytes for an integer
})
