# The app's rules, which every example in the guide must keep.

test_that("stock is the sum of movements, and no stock number is stored", {
  expect_false(any(c("on_hand", "stock") %in% names(shop$products)))
  pendant <- stock_history(shop, "NEC-0003")
  expect_equal(
    stock_on_hand(shop) |> filter(sku == "NEC-0003") |> pull(on_hand),
    sum(pendant$quantity)
  )
})

test_that("only the one scripted sale takes stock below zero", {
  below <- stock_on_hand(shop) |>
    filter(on_hand < 0)
  expect_equal(below$sku, "NEC-0003")
  expect_equal(below$on_hand, -1L)
})

test_that("showcase products end in their states, the rest healthy", {
  statuses <- product_statuses(shop)
  status_of <- \(sku) statuses$status[statuses$sku == sku]
  expect_equal(status_of("NEC-0003"), "below_zero")
  expect_equal(status_of("EAR-0004"), "out_still_selling")
  expect_equal(status_of("COI-0001"), "out_still_selling")
  expect_equal(status_of("BAN-0001"), "low")
  expect_equal(status_of("NEC-0005"), "low")
  expect_equal(status_of("SET-0006"), "new")
  expect_equal(status_of("NEC-0009"), "not_selling")
  others <- statuses |>
    filter(!sku %in% showcase_skus)
  expect_true(all(others$status == "healthy"))
})

test_that("a count changes stock only for the differences accepted", {
  adjustments <- shop$movements |>
    filter(kind == "count_adjustment")
  expect_setequal(
    paste(adjustments$sku, adjustments$quantity),
    c("EAR-0004 -1", "OTH-0001 -1", "COI-0001 1", "EAR-0001 -1")
  )
  # EAR-0006 was counted one over in Showcase 1, but left unticked.
  expect_false("EAR-0006" %in% adjustments$sku)
  expect_false(
    shop$count_lines |>
      filter(sku == "EAR-0006", count_id == 2) |>
      pull(accepted)
  )
})

test_that("an open count changes nothing", {
  open <- shop$counts |>
    filter(is.na(completed_at))
  expect_equal(open$location, "Showcase 2")
  adjustment_notes <- shop$movements |>
    filter(kind == "count_adjustment") |>
    pull(note)
  expect_false(any(grepl("Showcase 2", adjustment_notes)))
})

test_that("counting is blind: what's counted never depends on the ledger", {
  at <- shop$end_at
  count <- simulate_count(shop, at, types = "Earrings")

  # The same shelf with a ledger that's wrong by 5 pairs.
  wrong_ledger <- shop
  wrong_ledger$movements <- add_row(
    shop$movements,
    sku = "EAR-0001", date = at - 3600, kind = "sold", quantity = -5L,
    note = "keyed by mistake"
  )
  shelf_unchanged <- tibble(sku = "EAR-0001", change = 5L)
  recount <- simulate_count(
    wrong_ledger, at,
    types = "Earrings", shelf_changes = shelf_unchanged
  )

  expect_equal(recount$counted, count$counted)
  expect_false(identical(recount$expected, count$expected))
})

test_that("earrings count in pairs; odd singles are flagged, not rounded", {
  count <- simulate_count(
    shop, shop$end_at,
    types = "Earrings",
    odd_singles = tibble(sku = "EAR-0006", n = 1L)
  )
  expect_true(all(count$unit == "pair"))
  hoops <- count |> filter(sku == "EAR-0006")
  expect_equal(hoops$odd_singles, 1L)
  expect_equal(hoops$counted, hoops$on_shelf)
})

test_that("a theft and a miscount both show as differences in Review", {
  count <- simulate_count(
    shop, shop$end_at,
    types = c("Earrings", "Rings"),
    shelf_changes = tibble(sku = "EAR-0001", change = -1L),
    mistakes = tibble(sku = "RIN-0001", change = 1L)
  ) |>
    reconcile_count()
  expect_equal(count$result[count$sku == "EAR-0001"], "short")
  expect_equal(count$result[count$sku == "RIN-0001"], "over")
  expect_equal(
    count$value_at_cost[count$sku == "EAR-0001"],
    -count$cost[count$sku == "EAR-0001"]
  )
})

test_that("pairs, sets and pieces are never added together", {
  by_type <- stock_by_type(shop)
  expect_equal(
    by_type$unit,
    c("pair", "piece", "piece", "piece", "set", "piece", "piece")
  )
  summary <- simulate_count(shop, shop$end_at) |>
    reconcile_count() |>
    summarise_count()
  expect_setequal(summary$unit, c("pair", "piece", "set"))
})

test_that("stock below zero counts as none in the stock value", {
  by_type <- stock_by_type(shop)
  necklaces <- by_type |> filter(type == "Necklaces")
  on_hand <- stock_on_hand(shop) |>
    left_join(shop$products, by = "sku") |>
    filter(type == "Necklaces")
  expect_equal(necklaces$units, sum(pmax(0L, on_hand$on_hand)))
})

test_that("the same seed gives the same shop", {
  expect_identical(simulate_shop()$movements, shop$movements)
})
