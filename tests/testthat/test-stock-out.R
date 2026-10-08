# The stock the demo sends out when it starts, as the activity log shows it.

test_that("the demo sends earrings on jangad and a set for an order", {
  out <- shop$out_records
  expect_equal(out$sku, c("EAR-0001", "SET-0001"))
  expect_equal(out$place, c("jangad", "order"))
  expect_equal(out$units, c(2L, 1L))
  expect_equal(out$memo, c("41", "O-208"))
})

test_that("with no count open, a necklace goes to the karigar, long overdue", {
  no_count <- load_shop(end_on = reference_end, counting = FALSE)
  karigar <- filter(no_count$out_records, place == "karigar")
  expect_equal(karigar$sku, "NEC-0001")
  expect_true(karigar$due_back < no_count$end_at - 7 * 86400)
})

test_that("sending out keeps owned stock and takes it out of the shop", {
  owned <- stock_on_hand(shop) |> filter(sku == "EAR-0001")
  in_shop <- stock_in_shop(shop) |> filter(sku == "EAR-0001")
  expect_equal(owned$on_hand - in_shop$in_shop, 2L)
})

test_that("a count expects the stock in the shop, not what's out", {
  count <- simulate_count(shop, shop$end_at, types = "Earrings")
  jhumka <- filter(count, sku == "EAR-0001")
  expect_equal(
    jhumka$expected,
    stock_in_shop(shop) |> filter(sku == "EAR-0001") |> pull(in_shop)
  )
})
