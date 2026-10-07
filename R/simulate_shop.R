# The whole shop: every product's year, the counts and the ledger, as the
# app's demo builds it (JholokKit/Sources/JholokDemo/DemoScript.swift,
# `DemoScenario.make`).
#
# `simulate_shop()` returns tidy tables:
# - `types` and `products`: the catalogue;
# - `movements`: the ledger, one row per movement, signed (sales negative);
# - `counts` and `count_lines`: the counts and what was counted.
#
# Stock is never stored: `stock_on_hand()` adds up the movements.

shop_seed <- "7A112026"
shop_time_zone <- "Asia/Kolkata"

# `end_on` moves the whole story by whole weeks, as the app does, so that it
# ends on the latest Thursday on or before that date. Use the date the app's
# screenshots were taken, so the guide's dates match the pictures.
simulate_shop <- function(end_on = as.Date("2026-09-24"), counting = TRUE,
                          seed = shop_seed) {
  shift_days <- story_shift(end_on)
  open_count_day <- min(max(as_day(end_on) - shift_days, end_day), end_day + 6L)
  catalogue <- shop_catalogue()
  plans <- shop_plans(catalogue)
  seasons <- season_multipliers()
  snapshots <- c(whole_shop_day, showcase_day, open_count_day)

  # Each product gets two seeds from one main generator, in catalogue order:
  # one for its sales and one for rescuing it if the sales break a promise.
  main_rng <- new_splitmix64(u64_from_hex(seed))
  runs <- lapply(plans, \(plan) {
    sales_seed <- main_rng$next_u64()
    fix_seed <- main_rng$next_u64()
    settle_product(plan, sales_seed, fix_seed, seasons, snapshots)
  })

  counts <- story_counts(plans, runs, open_count_day, counting)
  to_time <- \(day, minute) story_time(day, minute, shift_days)

  movements <- bind_rows(
    lapply(names(runs), \(sku) mutate(runs[[sku]]$movements, sku = sku)),
    count_adjustments(counts$lines, counts$counts)
  ) |>
    mutate(
      position = match(sku, catalogue$sku),
      rank = if_else(kind == "count_adjustment", 3L, 2L)
    ) |>
    arrange(day, minute, rank, position) |>
    transmute(
      sku,
      date = to_time(day, minute),
      kind,
      quantity,
      note
    )

  products <- catalogue |>
    mutate(
      open_day = vapply(plans, \(plan) plan$open_day, 0L),
      archive_day = vapply(plans, \(plan) plan$archive_day, 0L),
      created_at = to_time(open_day, opening_minute),
      archived_at = to_time(archive_day, 20 * 60 + 45)
    ) |>
    select(-open_day, -archive_day)

  list(
    types = shop_types(),
    products = products,
    movements = movements,
    counts = counts$counts |>
      mutate(
        started_at = to_time(day, start_minute),
        completed_at = to_time(day, end_minute)
      ) |>
      select(count_id, location, notes, scope, started_at, completed_at),
    count_lines = counts$lines |>
      mutate(counted_at = to_time(day, minute)) |>
      select(count_id, sku, counted, counted_at, accepted),
    end_at = to_time(end_day, end_minute),
    shift_days = shift_days
  )
}

# Whole weeks from the story's end (24 September 2026) to `end_on`, so
# weekdays and festivals stay on the same days of the week.
story_shift <- function(end_on) {
  days <- as.integer(as.Date(end_on) - (first_day + end_day))
  7L * (days %/% 7L)
}

story_time <- function(day, minute, shift_days = 0L) {
  date <- first_day + day + shift_days
  lubridate::make_datetime(
    year = lubridate::year(date),
    month = lubridate::month(date),
    day = lubridate::mday(date),
    hour = minute %/% 60,
    min = minute %% 60,
    tz = shop_time_zone
  )
}

# "Whole shop" on 31 March 2026, "Showcase 1" on 12 September 2026 and, when
# `counting`, "Showcase 2", left open with four necklaces counted.
story_counts <- function(plans, runs, open_count_day, counting) {
  whole_shop <- story_count(
    plans, runs,
    count_id = 1L, day = whole_shop_day, start = clock(8, 30),
    end = clock(10, 30), every = 2L, location = "Whole shop",
    notes = "Financial year close", scope = character(),
    offsets = whole_shop_offsets, unticked = character()
  )
  showcase <- story_count(
    plans, runs,
    count_id = 2L, day = showcase_day, start = clock(8, 30),
    end = clock(10), every = 3L, location = "Showcase 1",
    notes = "A customer's repair piece was in the tray",
    scope = c("Earrings", "Rings"),
    offsets = showcase_offsets, unticked = showcase_unticked
  )
  counts <- list(whole_shop, showcase)
  if (counting) {
    counts <- c(counts, list(open_count(plans, runs, open_count_day)))
  }
  list(
    counts = bind_rows(lapply(counts, \(count) count$count)),
    lines = bind_rows(lapply(counts, \(count) count$lines))
  )
}

story_count <- function(plans, runs, count_id, day, start, end, every,
                        location, notes, scope, offsets, unticked) {
  in_scope <- Filter(\(plan) {
    plan$open_day <= day &&
      (is.na(plan$archive_day) || plan$archive_day > day) &&
      (length(scope) == 0 || plan$product$type %in% scope)
  }, plans)
  skus <- names(in_scope)
  on_hand <- vapply(skus, \(sku) {
    balance <- runs[[sku]]$opening_balances[as.character(day)]
    if (is.na(balance)) 0L else balance
  }, 0L)
  offset <- unname(offsets[skus])
  offset[is.na(offset)] <- 0L
  list(
    count = tibble(
      count_id = count_id,
      location = location,
      notes = notes,
      scope = list(scope),
      day = day,
      start_minute = start,
      end_minute = end
    ),
    lines = tibble(
      count_id = count_id,
      sku = skus,
      counted = unname(on_hand) + offset,
      expected = unname(on_hand),
      day = day,
      minute = start + 1L + every * (seq_along(skus) - 1L),
      accepted = !skus %in% unticked
    )
  )
}

open_count <- function(plans, runs, day) {
  on_hand <- vapply(open_count_skus, \(sku) {
    run <- runs[[sku]]
    balance <- run$opening_balances[as.character(day)]
    if (day <= end_day && !is.na(balance)) balance else run$on_hand
  }, 0L)
  list(
    count = tibble(
      count_id = 3L,
      location = "Showcase 2",
      notes = "",
      scope = list("Necklaces"),
      day = day,
      start_minute = clock(9),
      end_minute = NA_integer_
    ),
    lines = tibble(
      count_id = 3L,
      sku = open_count_skus,
      counted = unname(on_hand),
      expected = unname(on_hand),
      day = day,
      minute = clock(9, 2 + 3 * (seq_along(open_count_skus) - 1)),
      accepted = TRUE
    )
  )
}

# When a count is completed, the app records a "count adjustment" movement
# for every difference the approver accepted, so stock stays a sum of
# movements.
count_adjustments <- function(lines, counts) {
  lines |>
    inner_join(
      counts |>
        filter(!is.na(end_minute)) |>
        select(count_id, location, end_minute),
      by = "count_id"
    ) |>
    filter(accepted, counted != expected) |>
    transmute(
      sku,
      day,
      minute = end_minute,
      kind = "count_adjustment",
      quantity = counted - expected,
      note = paste("Stock count", location, sep = " · ")
    )
}

# Stock on hand at a moment: the sum of every movement up to then.
stock_on_hand <- function(shop, at = shop$end_at) {
  shop$movements |>
    filter(date <= at) |>
    summarise(on_hand = sum(quantity), .by = sku) |>
    right_join(select(shop$products, sku), by = "sku") |>
    mutate(on_hand = coalesce(on_hand, 0L))
}
