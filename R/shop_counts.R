# Counting, as the guide teaches it.
#
# A count compares three numbers for each product:
# - expected: what the ledger says should be there (the sum of movements);
# - on the shelf: what is really there, which can differ because of a theft,
#   a sale nobody entered or a delivery not yet keyed in;
# - counted: what the counter wrote down, which can differ from the shelf
#   because people make mistakes.
#
# The counter never sees `expected` (counting is blind), so `simulate_count()`
# makes `counted` from the shelf alone. Only `reconcile_count()`, which is
# Review, puts the counted number next to the expected one.

# A cached copy of the shop, since simulating it takes a few seconds. The
# cache is thrown away whenever the simulation's code changes.
load_shop <- function(end_on = as.Date("2026-09-24"), counting = TRUE) {
  code <- list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)
  fingerprint <- tools::md5sum(code) |>
    paste(collapse = "") |>
    paste(end_on, counting)
  key <- substr(rlang::hash(fingerprint), 1, 12)
  path <- here::here("_cache", paste0("shop-", key, ".rds"))
  if (file.exists(path)) {
    return(readRDS(path))
  }
  shop <- simulate_shop(end_on = end_on, counting = counting)
  dir.create(dirname(path), showWarnings = FALSE)
  saveRDS(shop, path)
  shop
}

# Each product's line of a count at `at`, for the given types (all of them
# when NULL).
#
# `shelf_changes` and `mistakes` are tables with columns `sku` and `change`:
# - `shelf_changes`: what really happened that the ledger doesn't know, such
#   as a stolen pair (-1);
# - `mistakes`: what the counter got wrong, such as a pair counted twice (+1).
# `odd_singles` lists single earrings found without their pair (`sku`, `n`):
# they are flagged, never rounded into pairs.
simulate_count <- function(shop, at, types = NULL,
                           shelf_changes = no_changes(),
                           mistakes = no_changes(),
                           odd_singles = no_odd_singles()) {
  in_scope <- shop$products |>
    filter(
      is.null(types) | type %in% types,
      created_at <= at,
      is.na(archived_at) | archived_at > at
    ) |>
    left_join(shop$types, by = "type") |>
    select(sku, type, unit, name, variant, cost, price)

  ledger <- stock_on_hand(shop, at) |>
    rename(expected = on_hand)

  on_shelf <- ledger |>
    left_join(total_change(shelf_changes), by = "sku") |>
    transmute(sku, on_shelf = pmax(0L, expected + coalesce(change, 0L)))

  counted <- on_shelf |>
    left_join(total_change(mistakes), by = "sku") |>
    transmute(sku, counted = pmax(0L, on_shelf + coalesce(change, 0L)))

  in_scope |>
    left_join(ledger, by = "sku") |>
    left_join(on_shelf, by = "sku") |>
    left_join(counted, by = "sku") |>
    left_join(rename(odd_singles, odd_singles = n), by = "sku") |>
    mutate(odd_singles = coalesce(as.integer(odd_singles), 0L))
}

no_odd_singles <- function() {
  tibble(sku = character(), n = integer())
}

no_changes <- function() {
  tibble(sku = character(), change = integer())
}

total_change <- function(changes) {
  summarise(changes, change = as.integer(sum(change)), .by = sku)
}

# Review: each counted line next to what was expected, with the difference in
# units and at cost. Differences are kept per unit; pairs, sets and pieces are
# never added together.
reconcile_count <- function(count_lines) {
  count_lines |>
    mutate(
      expected = coalesce(expected, 0L),
      difference = counted - expected,
      result = case_when(
        difference == 0 ~ "matched",
        difference < 0 ~ "short",
        .default = "over"
      ),
      value_at_cost = difference * cost
    )
}

# The headline of a count, per unit: how many products matched, and the units
# and value short and over.
summarise_count <- function(reconciled) {
  reconciled |>
    summarise(
      products = n(),
      matched = sum(result == "matched"),
      short_units = -sum(difference[result == "short"]),
      over_units = sum(difference[result == "over"]),
      short_value = -sum(value_at_cost[result == "short"], na.rm = TRUE),
      over_value = sum(value_at_cost[result == "over"], na.rm = TRUE),
      .by = unit
    ) |>
    mutate(matched_share = share(matched, products))
}
