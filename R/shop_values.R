# What the stock is and what it's worth, by type, as the Overview shows it.
#
# Stock below zero counts as none here, as in the app: a shelf can't hold
# minus one pendant. Products with no cost are left out of the value and
# counted, so a total never hides what it is missing.

stock_by_type <- function(shop, at = shop$end_at) {
  stock_on_hand(shop, at) |>
    left_join(shop$products, by = "sku") |>
    left_join(shop$types, by = "type") |>
    mutate(in_stock = pmax(0L, on_hand)) |>
    summarise(
      products = n(),
      units = sum(in_stock),
      value_at_cost = sum(in_stock * cost, na.rm = TRUE),
      value_at_price = sum(in_stock * price, na.rm = TRUE),
      no_cost = sum(in_stock > 0 & is.na(cost)),
      no_price = sum(in_stock > 0 & is.na(price)),
      .by = c(type, unit, sort_order)
    ) |>
    arrange(sort_order) |>
    select(-sort_order) |>
    mutate(units_words = describe_units(units, unit))
}

# The stock of one product, movement by movement: the running total is what
# the app shows as "on hand" at each moment.
stock_history <- function(shop, product_sku) {
  shop$movements |>
    filter(sku == product_sku) |>
    mutate(on_hand = cumsum(quantity))
}

# The value of the whole shop's stock at the end of every day.
daily_stock_value <- function(shop, basis = c("cost", "price")) {
  basis <- rlang::arg_match(basis)
  days <- seq(
    as.Date(min(shop$movements$date), tz = shop_time_zone),
    as.Date(shop$end_at, tz = shop_time_zone),
    by = "day"
  )
  unit_value <- shop$products |>
    select(sku, value = all_of(basis))
  shop$movements |>
    mutate(day = as.Date(date, tz = shop_time_zone)) |>
    summarise(change = sum(quantity), .by = c(sku, day)) |>
    tidyr::complete(sku, day = days, fill = list(change = 0L)) |>
    arrange(sku, day) |>
    mutate(on_hand = cumsum(change), .by = sku) |>
    left_join(unit_value, by = "sku") |>
    summarise(value = sum(pmax(0L, on_hand) * value, na.rm = TRUE), .by = day)
}

# Each product's state at the end, by the rules of the Overview's "needs
# attention" list: below zero, out (still selling or not), new, low, not
# selling, or healthy.
product_statuses <- function(shop) {
  last <- end_day
  shop$movements |>
    mutate(
      day = as.integer(
        as.Date(date, tz = shop_time_zone) - first_day - shop$shift_days
      )
    ) |>
    tidyr::nest(movements = -sku) |>
    mutate(status = purrr::map_chr(movements, \(moves) {
      first <- min(moves$day)
      daily <- moves |>
        summarise(change = sum(quantity), .by = day)
      change <- integer(last - first + 1)
      change[daily$day - first + 1] <- daily$change
      run <- list(
        movements = moves,
        closing = cumsum(change),
        first_day = first,
        on_hand = sum(moves$quantity)
      )
      stock_status(rate_window(run, last))
    })) |>
    select(sku, status)
}
