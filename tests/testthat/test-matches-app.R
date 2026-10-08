# The guide's shop must be the app's demo shop, sale for sale, so the numbers
# in the guide match the screenshots. The fixtures are the app's own output,
# written by scripts/app-demo-dump; run it again whenever the app's demo
# changes.

read_fixture <- function(name) {
  readr::read_csv(
    test_path("fixtures", name),
    col_types = readr::cols(.default = "c")
  )
}

as_minutes <- function(time) {
  format(time, "%Y-%m-%d %H:%M", tz = shop_time_zone)
}

test_that("every movement is the app's, in the same order", {
  app_movements <- read_fixture("app_events.csv") |>
    filter(event == "movement") |>
    transmute(
      sku, date, kind,
      quantity = as.integer(quantity),
      note = coalesce(note, "")
    )
  # The app records count adjustments as it completes the counts, and sends
  # stock out when it starts, so neither is in the demo's story file.
  guide_movements <- shop$movements |>
    filter(!kind %in% c("count_adjustment", "sent_out")) |>
    transmute(sku, date = as_minutes(date), kind, quantity, note)

  expect_equal(guide_movements, app_movements)
})

test_that("every product opens and is archived when the app's does", {
  app_events <- read_fixture("app_events.csv")
  created <- app_events |>
    filter(event == "create") |>
    select(sku, date)
  archived <- app_events |>
    filter(event == "archive") |>
    select(sku, date)

  # The app lists products by when they were added; compare by SKU.
  expect_equal(
    shop$products |>
      transmute(sku, date = as_minutes(created_at)) |>
      arrange(sku),
    arrange(created, sku)
  )
  expect_equal(
    shop$products |>
      filter(!is.na(archived_at)) |>
      transmute(sku, date = as_minutes(archived_at)),
    archived
  )
})

test_that("every count line is the app's", {
  app_lines <- read_fixture("app_counts.csv") |>
    transmute(
      location, sku,
      counted = as.integer(counted),
      counted_at,
      accepted = unticked == "FALSE"
    )
  guide_lines <- shop$count_lines |>
    left_join(select(shop$counts, count_id, location), by = "count_id") |>
    transmute(
      location, sku, counted,
      counted_at = as_minutes(counted_at),
      accepted
    )

  expect_equal(guide_lines, app_lines)
})
