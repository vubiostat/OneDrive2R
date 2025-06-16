context("shared")

test_that("drive requires a ms_drive class",{
  local_reproducible_output(width = 200)
  expect_error(
    shared(TRUE),
    "Variable 'drive': Must inherit from class 'ms_drive'")
})

