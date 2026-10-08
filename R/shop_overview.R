# What the Overview shows, worked out from the shop the same way
# (JholokDomain/Insights: Reports, Attention, SeasonCalendar).

# The festivals the Overview names on its sales chart. Labels only: they never
# change a figure. The demo moves them by the same whole weeks as its story.
festivals <- tribble(
  ~festival, ~date,
  "Raksha Bandhan", "2025-08-09",
  "Ganesh Chaturthi", "2025-08-27",
  "Navratri", "2025-09-22",
  "Dussehra", "2025-10-02",
  "Karwa Chauth", "2025-10-10",
  "Dhanteras", "2025-10-18",
  "Diwali", "2025-10-20",
  "Gudi Padwa", "2026-03-19",
  "Akshaya Tritiya", "2026-04-19",
  "Raksha Bandhan", "2026-08-28",
  "Ganesh Chaturthi", "2026-09-14",
  "Navratri", "2026-10-11",
  "Dussehra", "2026-10-20",
  "Karwa Chauth", "2026-10-29",
  "Dhanteras", "2026-11-06",
  "Diwali", "2026-11-08"
) |>
  mutate(date = as.Date(date))

# Weeks run Sunday to Saturday, as on the Overview.
week_of <- function(date) {
  lubridate::floor_date(
    as.Date(date, tz = shop_time_zone),
    unit = "week",
    week_start = 7
  )
}

# Sales by week, after returns: their value at today's list price and the
# items sold (any unit), with the festival that fell in the week, if any.
weekly_sales <- function(shop) {
  festival_weeks <- festivals |>
    mutate(week = week_of(date + shop$shift_days)) |>
    summarise(festival = first(festival), .by = week)
  shop$movements |>
    filter(kind %in% c("sold", "returned")) |>
    left_join(select(shop$products, sku, price), by = "sku") |>
    mutate(week = week_of(date)) |>
    summarise(
      value = sum(-quantity * price, na.rm = TRUE),
      items = sum(-quantity),
      .by = week
    ) |>
    tidyr::complete(
      week = seq(min(week), week_of(shop$end_at), by = "week"),
      fill = list(value = 0, items = 0L)
    ) |>
    left_join(festival_weeks, by = "week") |>
    arrange(week)
}

# The Needs attention lists, one row per product and list. Archived products,
# and products that are out with no recent sales or new, aren't listed.
attention_lists <- function(shop) {
  list_names <- c(
    below_zero = "Below zero",
    out_still_selling = "Out of stock, still selling",
    low = "Running low",
    not_selling = "Not selling"
  )
  products <- shop$products |>
    filter(is.na(archived_at)) |>
    left_join(product_statuses(shop), by = "sku") |>
    left_join(stock_on_hand(shop), by = "sku")
  by_status <- products |>
    filter(status %in% names(list_names)) |>
    mutate(list = unname(list_names[status]))
  missing <- bind_rows(
    products |>
      filter(on_hand > 0, is.na(cost)) |>
      mutate(list = "No cost"),
    products |>
      filter(on_hand > 0, is.na(price)) |>
      mutate(list = "No price")
  )
  bind_rows(by_status, missing) |>
    mutate(
      list = factor(list, levels = c(list_names, "No cost", "No price"))
    ) |>
    arrange(list, sku) |>
    select(list, sku, name, variant, on_hand)
}

# Each type's stock value at cost at a moment, leaving out archived products
# and counting stock below zero as none, as the Overview does.
value_by_type <- function(shop, at = shop$end_at) {
  stock_on_hand(shop, at) |>
    inner_join(filter(shop$products, is.na(archived_at)), by = "sku") |>
    summarise(value = sum(pmax(0L, on_hand) * cost, na.rm = TRUE), .by = type)
}
