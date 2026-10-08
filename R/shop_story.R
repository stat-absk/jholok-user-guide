# The fixed parts of the shop's year
# (JholokKit/Sources/JholokDemo/DemoScript.swift): openings, buying before the
# festivals, the big festival days, returns, the products that end in a state
# worth showing ("out of stock", "running low"), and the counts.

whole_shop_day <- as_day("2026-03-31")
showcase_day <- as_day("2026-09-12")
open_count_skus <- c("NEC-0001", "NEC-0002", "NEC-0004", "NEC-0006")

# Products that end in a state the Overview shows; every other product ends in
# good health.
showcase_skus <- c(
  "EAR-0004", "COI-0001", "BAN-0001", "NEC-0005", "NEC-0003", "NEC-0009",
  "OTH-0004", "BAN-0004", "NEC-0008", "EAR-0008", "SET-0006", "BAN-0007"
)

# How far each count is from the stock on hand. Every difference is accepted
# except those in `unticked`.
whole_shop_offsets <- c("EAR-0004" = -1L, "OTH-0001" = -1L, "COI-0001" = 1L)
showcase_offsets <- c("EAR-0001" = -1L, "EAR-0006" = 1L)
showcase_unticked <- "EAR-0006"
# Odd single earrings found beside a count: Showcase 1's short jhumka pair
# left one behind. Singles never change stock.
showcase_singles <- c("EAR-0001" = 1L)

clock <- function(hour, minute = 0) {
  as.integer(hour * 60 + minute)
}

new_plan <- function(product) {
  list(
    product = product,
    open_day = 0L,
    draws = TRUE,
    reorders = TRUE,
    script_from = NA_integer_,
    sell_down = NULL,
    floor = NULL,
    scripted = tibble(
      day = integer(),
      minute = integer(),
      kind = character(),
      quantity = integer(),
      note = character(),
      may_go_below_zero = logical()
    ),
    count_deltas = tibble(
      day = integer(),
      minute = integer(),
      delta = integer()
    ),
    min_net_sold = 0L,
    must_end_healthy = FALSE,
    archive_day = NA_integer_
  )
}

script_movement <- function(plan, day, kind, quantity, minute = NA, note = NA,
                            may_go_below_zero = FALSE) {
  plan$scripted <- add_row(
    plan$scripted,
    day = as.integer(day), minute = as.integer(minute), kind = kind,
    quantity = as.integer(quantity), note = note,
    may_go_below_zero = may_go_below_zero
  )
  plan
}

sell_down <- function(from, through, target, ends_with_sale = FALSE,
                      last_sale_minute = NA) {
  list(
    from = as.integer(from),
    through = as.integer(through),
    target = as.integer(target),
    ends_with_sale = ends_with_sale,
    last_sale_minute = as.integer(last_sale_minute)
  )
}

shop_plans <- function(catalogue = shop_catalogue()) {
  plans <- lapply(seq_len(nrow(catalogue)), \(i) new_plan(catalogue[i, ]))
  names(plans) <- catalogue$sku

  # Adds the same kind of movement for several products on one day, in SKU
  # order, as the app does.
  add_movements <- function(plans, date, kind, units, note = NA) {
    minute <- if (kind == "received") receipt_minute else NA
    for (sku in sort(names(units))) {
      plans[[sku]] <- script_movement(
        plans[[sku]], as_day(date), kind, units[[sku]],
        minute = minute, note = note
      )
    }
    plans
  }

  # Openings. Slow and dead products only move when the story says so.
  plans[["OTH-0004"]]$open_day <- as_day("2025-12-20")
  plans[["SET-0006"]]$open_day <- as_day("2026-09-16")
  plans[["SET-0006"]]$draws <- FALSE
  plans[["SET-0006"]]$reorders <- FALSE
  for (sku in names(plans)) {
    plan <- plans[[sku]]
    if (plan$product$profile %in% c("slow", "dead")) {
      plan$draws <- FALSE
      plan$reorders <- FALSE
    }
    plan <- script_movement(
      plan, plan$open_day, "opening", plan$product$opening,
      minute = opening_minute, note = "Opening stock"
    )
    plan$must_end_healthy <- !sku %in% showcase_skus
    plans[[sku]] <- plan
  }

  # Buying before the festivals.
  plans <- plans |>
    add_movements("2025-09-01", "received", c(
      "COI-0001" = 20, "SET-0003" = 3, "NEC-0003" = 4, "EAR-0001" = 2
    )) |>
    add_movements("2025-10-08", "received", c(
      "COI-0001" = 60, "COI-0002" = 10, "NEC-0003" = 6, "SET-0003" = 4,
      "EAR-0001" = 4, "EAR-0003" = 3
    )) |>
    add_movements("2026-04-10", "received", c(
      "COI-0001" = 30, "COI-0002" = 6, "RIN-0001" = 8, "NEC-0005" = 4
    )) |>
    add_movements("2026-09-16", "received", c(
      "SET-0003" = 4, "EAR-0001" = 4, "EAR-0003" = 3, "COI-0004" = 20,
      "BAN-0005" = 4
    ))

  # Festival sales on top of the day's usual sales: Dhanteras and Akshaya
  # Tritiya.
  plans <- plans |>
    add_movements("2025-10-18", "sold", c(
      "COI-0001" = -38, "COI-0002" = -9, "COI-0003" = -3, "COI-0004" = -12,
      "NEC-0003" = -4, "SET-0003" = -3, "EAR-0001" = -2
    )) |>
    add_movements("2026-04-19", "sold", c(
      "COI-0001" = -25, "COI-0002" = -6, "COI-0003" = -2, "RIN-0001" = -3,
      "NEC-0005" = -2
    ))

  # Returns, and the one correction made outside a count.
  returns <- tribble(
    ~sku, ~date, ~minute, ~note,
    "EAR-0001", "2025-10-25", clock(12, 40), "Returned after Diwali",
    "RIN-0001", "2025-11-20", clock(16, 10), "Size exchange",
    "RIN-0003", "2026-05-03", clock(13, 20), "Returned within 7 days",
    "NEC-0001", "2026-09-02", clock(17, 5), "Clasp fault"
  )
  for (i in seq_len(nrow(returns))) {
    sku <- returns$sku[i]
    plans[[sku]] <- script_movement(
      plans[[sku]], as_day(returns$date[i]), "returned", 1,
      minute = returns$minute[i], note = returns$note[i]
    )
  }
  plans[["NEC-0001"]] <- script_movement(
    plans[["NEC-0001"]], as_day("2026-01-08"), "adjustment", -1,
    minute = clock(11, 30), note = "Damaged on display, sent for melting"
  )

  plans <- add_showcase_states(plans)

  # Not selling: each sold once in the year.
  plans <- plans |>
    add_movements("2025-12-05", "sold", c("BAN-0004" = -1)) |>
    add_movements("2026-03-02", "sold", c("NEC-0008" = -1)) |>
    add_movements("2026-05-21", "sold", c("EAR-0008" = -1))

  # Differences a count accepted move the stock when the count completes.
  for (sku in names(whole_shop_offsets)) {
    plans[[sku]]$count_deltas <- add_row(
      plans[[sku]]$count_deltas,
      day = whole_shop_day, minute = clock(10, 30),
      delta = whole_shop_offsets[[sku]]
    )
  }
  accepted <- setdiff(names(showcase_offsets), showcase_unticked)
  for (sku in accepted) {
    plans[[sku]]$count_deltas <- add_row(
      plans[[sku]]$count_deltas,
      day = showcase_day, minute = clock(10),
      delta = showcase_offsets[[sku]]
    )
  }
  plans
}

# The products that end the story in a state the Overview shows.
add_showcase_states <- function(plans) {
  window_start <- end_day - rate_window_days + 1L

  # Out of stock and still selling.
  plans[["EAR-0004"]]$script_from <- as_day("2026-08-20")
  plans[["EAR-0004"]]$sell_down <- sell_down(
    as_day("2026-08-20"), as_day("2026-09-18"), 0,
    ends_with_sale = TRUE, last_sale_minute = clock(15)
  )
  plans[["EAR-0004"]]$min_net_sold <- 5L

  # Out of stock and still selling; the last coin goes on Ganesh Chaturthi.
  plans[["COI-0001"]]$script_from <- as_day("2026-05-01")
  plans[["COI-0001"]]$sell_down <- sell_down(
    as_day("2026-05-01"), as_day("2026-09-14"), 0,
    ends_with_sale = TRUE
  )

  # Running low: 2 left, in stock all 90 days, at least 10 sold in twos.
  plans[["BAN-0001"]]$script_from <- as_day("2026-08-20")
  plans[["BAN-0001"]]$sell_down <- sell_down(as_day("2026-08-20"), end_day, 2)
  plans[["BAN-0001"]]$floor <- list(from = window_start, units = 2L)
  plans[["BAN-0001"]]$min_net_sold <- 10L

  # Running low: 1 left, never at 0, at least 5 sold.
  plans[["NEC-0005"]]$script_from <- as_day("2026-08-01")
  plans[["NEC-0005"]]$sell_down <- sell_down(as_day("2026-08-01"), end_day, 1)
  plans[["NEC-0005"]]$floor <- list(from = 0L, units = 1L)
  plans[["NEC-0005"]]$min_net_sold <- 5L

  # Below zero: the last pendant sells on 12 September, and a sale on the 20th
  # is entered before the delivery of 6 is.
  plans[["NEC-0003"]]$script_from <- as_day("2026-08-01")
  plans[["NEC-0003"]]$sell_down <- sell_down(
    as_day("2026-08-01"), as_day("2026-09-12"), 0,
    ends_with_sale = TRUE
  )
  plans[["NEC-0003"]] <- script_movement(
    plans[["NEC-0003"]], as_day("2026-09-20"), "sold", -1,
    minute = clock(12), note = "Walk-in, receipt of 6 not yet entered",
    may_go_below_zero = TRUE
  )

  # Never reordered: its 6 sell through the year, the last on 14 June 2026,
  # and it is archived a week later.
  plans[["BAN-0007"]]$draws <- FALSE
  plans[["BAN-0007"]]$reorders <- FALSE
  plans[["BAN-0007"]]$script_from <- 0L
  plans[["BAN-0007"]]$sell_down <- sell_down(
    0, as_day("2026-06-14"), 0,
    ends_with_sale = TRUE
  )
  plans[["BAN-0007"]]$archive_day <- as_day("2026-06-20")
  plans
}
