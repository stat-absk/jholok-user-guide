# The source check can only flag a chapter whose sources it knows.
source(here::here("scripts", "check_sources.R"))

test_that("every chapter lists the app files it relies on", {
  expect_length(unwatched_chapters(), 0)
})

test_that("every source in sources.csv is still in the app", {
  missing <- missing_sources()
  expect_equal(nrow(missing), 0, info = paste(missing$source, collapse = ", "))
})

test_that("a changed file flags the chapters that rely on it", {
  stale <- stale_targets(
    c("JholokKit/Sources/JholokDomain/OddSingles.swift", "README.md")
  )
  expect_setequal(
    stale$target,
    c(
      "01-stock-basics", "03-counting-and-reconciliation",
      "08-a-count-start-to-finish"
    )
  )
  expect_setequal(
    stale_targets("Jholok/DevTools/DemoBoxes/demo-box-1.json")$target,
    "the sample boxes"
  )
})

test_that("the last release names an app commit", {
  expect_match(last_checked_commit(), "^[0-9a-f]{7,40}$")
})
