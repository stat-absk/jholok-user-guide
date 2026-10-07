# Figures written as the app writes them (JholokDomain IndianMoney and
# InsightSentences tests).

test_that("rupees use Indian grouping", {
  expect_equal(rupees(27829600), "₹2,78,29,600")
  expect_equal(rupees(116640), "₹1,16,640")
  expect_equal(rupees(-4120000), "−₹41,20,000")
})

test_that("large amounts are three figures in lakh or crore", {
  nbsp <- " "
  expect_equal(rupees_short(86400), "₹86,400")
  expect_equal(rupees_short(114000), paste0("₹1.14", nbsp, "L"))
  expect_equal(rupees_short(3840000), paste0("₹38.4", nbsp, "L"))
  expect_equal(rupees_short(400000), paste0("₹4.00", nbsp, "L"))
  expect_equal(rupees_short(26000000), paste0("₹2.60", nbsp, "Cr"))
  expect_equal(rupees_short(12340000000), paste0("₹1,234", nbsp, "Cr"))
  expect_equal(rupees_short(9996000), paste0("₹1.00", nbsp, "Cr"))
})

test_that("a share of fewer than 10 is never a percentage", {
  expect_equal(share(3, 4), "3 of 4")
  expect_equal(share(9, 9), "9 of 9")
  expect_equal(share(11, 13), "85%")
  expect_equal(share(0, 10), "0%")
  expect_true(is.na(share(0, 0)))
})

test_that("units are named one at a time", {
  expect_equal(
    describe_units(c(1, 3, 1, 12), c("pair", "pair", "set", "piece")),
    c("1 pair", "3 pairs", "1 set", "12 pieces")
  )
  expect_equal(
    list_words(c("3 pairs", "2 sets", "5 pieces")),
    "3 pairs, 2 sets and 5 pieces"
  )
})
