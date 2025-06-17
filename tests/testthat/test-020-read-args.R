context("read_azure")

test_that("drive requires an ms_drive",{
  local_reproducible_output(width = 200)
  expect_error(
    read_azure(TRUE, "/path/somewhere.csv"),
    "Variable 'drive': Must inherit from class 'ms_drive'")
  expect_error(
    read_azure(NULL, "/path/somewhere.csv"),
    "Variable 'drive': Must inherit from class 'ms_drive'")
})

test_that("path is a string",{
  local_reproducible_output(width = 200)
  expect_error(
    read_azure(structure(NA, class="ms_drive"), TRUE),
    "Variable 'path': Must be of type 'string'")
  expect_error(
    read_azure(structure(NA, class="ms_drive"), NULL),
    "Variable 'path': Must be of type 'string'")
  expect_error(
    read_azure(structure(NA, class="ms_drive"), c('a','b')),
    "Variable 'path': Must have length 1")
})

test_that("FUN is a function",{
  local_reproducible_output(width = 200)
  expect_error(
    read_azure(structure(NA, class="ms_drive"), "/a/b.csv", FUN=TRUE),
    "Variable 'FUN': Must be a function")
})

