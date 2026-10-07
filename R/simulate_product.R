# One product's year, day by day, as the app's demo simulates it
# (JholokKit/Sources/JholokDemo/DemoSimulation.swift).
#
# Each day runs in this order:
# 1. what the story fixes for that day (openings, festival sales, returns);
# 2. the day's random sales, never more than is on the shelf;
# 3. on Wednesdays, the weekly order that refills stock to its par;
# 4. orders arriving that day.
#
# The order of the random draws matters: R must draw the same numbers in the
# same order as the app, or every later sale differs.

opening_minute <- 10 * 60
receipt_minute <- 10 * 60 + 30
sales_open <- 11 * 60
sales_close <- 20 * 60 + 30
order_weekday <- 4L # Wednesday
lead_days <- 7L
rate_window_days <- 90L
supplier_lead_time <- 21

# The average number sold on a day. Written in the same order as the app, so
# the result is the same to the last bit.
daily_mean <- function(product, day, seasons) {
  product$base_per_week / 7 * seasons[day + 1, product$profile] *
    weekday_factor(day)
}

sale_minute <- function(day, draw) {
  close <- if (day == end_day) end_minute else sales_close
  min(close, sales_open + floor(draw * (close - sales_open + 1)))
}

sale_note <- function(product, day, draw) {
  if (day %in% festival_days) {
    return("Festival")
  }
  if (product$profile == "bridal" && draw < 0.2) {
    return("Wedding order")
  }
  "Walk-in"
}

# An order arrives a week later, or on Wednesday when that is the closed
# Tuesday.
arrival_day <- function(day) {
  arrival <- day + lead_days
  if (is_open(arrival)) arrival else arrival + 1L
}

# Swift's `%` keeps the sign of the left side; R's `%%` doesn't.
swift_remainder <- function(x, y) {
  x - y * trunc(x / y)
}

# An open day, picked in proportion to how busy the product is on each.
pick_day <- function(days, product, seasons, rng) {
  open_days <- days[is_open(days)]
  if (length(open_days) == 0) {
    return(NA_integer_)
  }
  means <- vapply(open_days, \(day) daily_mean(product, day, seasons), 0)
  weights <- if (any(means > 0)) means else rep(1, length(open_days))
  # `Reduce()` adds left to right as Swift does; `sum()` rounds differently.
  target <- rng$next_unit() * Reduce(`+`, weights)
  for (i in seq_along(open_days)) {
    if (target < weights[i]) {
      return(open_days[i])
    }
    target <- target - weights[i]
  }
  open_days[length(open_days)]
}

simulate_product <- function(plan, seed, seasons, fixes = empty_fixes(),
                             snapshots = integer()) {
  product <- plan$product
  per_sale <- if (product$sells_in_twos) 2L else 1L
  first <- max(plan$open_day, 0L)
  window_start <- end_day - rate_window_days + 1L
  rng <- new_splitmix64(seed)

  balance <- 0L
  order_days <- integer()
  order_units <- integer()
  schedule <- integer(end_day + 1)
  carry <- 0L
  sold_in_window <- FALSE
  failure <- NULL

  movement_day <- integer()
  movement_minute <- integer()
  movement_kind <- character()
  movement_quantity <- integer()
  movement_note <- character()
  opening_balances <- integer()
  closing <- integer()

  fail <- function(kind, day = NA_integer_) {
    if (is.null(failure)) {
      failure <<- list(kind = kind, day = day)
    }
  }

  available <- function(day) {
    floor_units <- 0L
    if (!is.null(plan$floor) && day >= plan$floor$from) {
      floor_units <- plan$floor$units
    }
    units <- max(0L, balance - floor_units)
    units - swift_remainder(units, per_sale)
  }

  record <- function(day, minute, kind, quantity, note) {
    balance <<- as.integer(balance + quantity)
    movement_day <<- c(movement_day, day)
    movement_minute <<- c(movement_minute, minute)
    movement_kind <<- c(movement_kind, kind)
    movement_quantity <<- c(movement_quantity, quantity)
    movement_note <<- c(movement_note, note)
    if (kind == "sold" && day >= window_start) {
      sold_in_window <<- TRUE
    }
  }

  scripted <- plan$scripted
  deltas <- plan$count_deltas
  sell_down <- plan$sell_down

  for (day in first:end_day) {
    if (day %in% snapshots) {
      opening_balances[as.character(day)] <- balance
    }
    open <- is_open(day)
    in_script <- !is.na(plan$script_from) && day >= plan$script_from

    # The sell-down: what is on hand and on order, sold down to a target over
    # a set stretch of days, in place of the random draws.
    if (!is.null(sell_down) && day == sell_down$from) {
      in_stretch <- function(days) {
        days >= sell_down$from & days <= sell_down$through
      }
      incoming <- sum(order_units[order_days <= sell_down$through])
      planned <- sum(scripted$quantity[in_stretch(scripted$day)]) +
        sum(deltas$delta[in_stretch(deltas$day)])
      units <- balance + incoming + planned - sell_down$target
      sales <- trunc(units / per_sale)
      cannot_sell_down <- units < 0 ||
        swift_remainder(units, per_sale) != 0 ||
        (sell_down$ends_with_sale && sales < 1)
      if (cannot_sell_down) {
        fail("short_of_stock", sell_down$from)
      } else {
        spread <- sales - sell_down$ends_with_sale
        last <- sell_down$through - sell_down$ends_with_sale
        days <- if (last >= sell_down$from) sell_down$from:last else integer()
        for (i in seq_len(spread)) {
          picked <- pick_day(days, product, seasons, rng)
          if (is.na(picked)) {
            carry <- carry + per_sale
          } else {
            schedule[picked + 1] <- schedule[picked + 1] + 1L
          }
        }
      }
    }

    # 1. What the story fixes for the day, in time order.
    todays_script <- which(scripted$day == day)
    todays_deltas <- which(deltas$day == day)
    steps <- run_order(todays_script, todays_deltas, scripted, deltas, day, rng)
    for (step in seq_len(nrow(steps))) {
      row <- steps$row[step]
      if (steps$is_delta[step]) {
        delta <- deltas$delta[row]
        if (balance + delta < 0) {
          fail("short_of_stock", day)
        } else {
          balance <- as.integer(balance + delta)
        }
        next
      }
      item <- scripted[row, ]
      minute <- steps$minute[step]
      if (item$kind == "sold") {
        note_draw <- rng$next_unit()
        wanted <- -item$quantity
        units <- if (item$may_go_below_zero) {
          wanted
        } else {
          min(wanted, available(day))
        }
        if (units < wanted) fail("short_of_stock", day)
        if (units > 0) {
          note <- item$note
          if (is.na(note)) note <- sale_note(product, day, note_draw)
          record(day, minute, "sold", -units, note)
        }
      } else if (item$kind == "adjustment" && item$quantity < 0) {
        if (balance + item$quantity < 0) {
          fail("short_of_stock", day)
        } else {
          note <- if (is.na(item$note)) "" else item$note
          record(day, minute, "adjustment", item$quantity, note)
        }
      } else if (item$kind == "received") {
        note <- if (is.na(item$note)) product$supplier else item$note
        record(day, minute, "received", item$quantity, note)
      } else {
        note <- if (is.na(item$note)) "" else item$note
        record(day, minute, item$kind, item$quantity, note)
      }
    }

    # 2. The day's random sales, or the sell-down's.
    if (open && plan$draws && !in_script) {
      demand <- rng$poisson(daily_mean(product, day, seasons)) * per_sale
      time_draw <- rng$next_unit()
      note_draw <- rng$next_unit()
      units <- min(demand, available(day))
      if (units == 0 && day %in% fixes$keep_alive_days && !sold_in_window) {
        units <- min(per_sale, available(day))
      }
      if (units > 0) {
        record(
          day, sale_minute(day, time_draw), "sold", -units,
          sale_note(product, day, note_draw)
        )
      }
    }
    in_sell_down <- !is.null(sell_down) &&
      day >= sell_down$from && day <= sell_down$through
    if (in_sell_down && open) {
      is_last <- sell_down$ends_with_sale && day == sell_down$through
      wanted <- schedule[day + 1] * per_sale + carry + is_last * per_sale
      units <- min(wanted, available(day))
      carry <- wanted - units
      if (units > 0) {
        time_draw <- rng$next_unit()
        note_draw <- rng$next_unit()
        minute <- sale_minute(day, time_draw)
        if (is_last && !is.na(sell_down$last_sale_minute)) {
          minute <- sell_down$last_sale_minute
        }
        record(day, minute, "sold", -units, sale_note(product, day, note_draw))
      }
    }
    if (!is.null(sell_down) && day == sell_down$through && carry > 0) {
      fail("short_of_stock", sell_down$from)
    }

    # 3. The weekly top-up: back up to par, counting what is already on order.
    forced <- day %in% fixes$forced_orders
    order_day <- open && weekday_number(day) == order_weekday
    tops_up <- plan$reorders && product$restocks && !in_script
    if (tops_up && (order_day || forced)) {
      units <- product$par - balance - sum(order_units)
      if (forced) units <- max(units, per_sale)
      units <- units + swift_remainder(units, per_sale)
      if (units > 0) {
        order_days <- c(order_days, arrival_day(day))
        order_units <- c(order_units, as.integer(units))
      }
    }

    # 4. Orders arriving today.
    arriving <- order_days == day
    for (units in order_units[arriving]) {
      record(day, receipt_minute, "received", units, product$supplier)
    }
    order_days <- order_days[!arriving]
    order_units <- order_units[!arriving]

    closing <- c(closing, balance)
  }

  list(
    movements = tibble(
      day = movement_day,
      minute = as.integer(movement_minute),
      kind = movement_kind,
      quantity = as.integer(movement_quantity),
      note = movement_note
    ),
    opening_balances = opening_balances,
    closing = closing,
    first_day = first,
    on_hand = balance,
    failure = failure
  )
}

empty_fixes <- function() {
  list(forced_orders = integer(), keep_alive_days = integer())
}

# The day's fixed events in the order they happen: by minute, with count
# corrections after movements at the same minute. A fixed sale with no time
# draws one, in the order the story lists them.
run_order <- function(script_rows, delta_rows, scripted, deltas, day, rng) {
  if (length(script_rows) + length(delta_rows) == 0) {
    return(tibble(minute = integer(), row = integer(), is_delta = logical()))
  }
  script_minutes <- scripted$minute[script_rows]
  for (i in seq_along(script_minutes)) {
    if (is.na(script_minutes[i])) {
      script_minutes[i] <- sale_minute(day, rng$next_unit())
    }
  }
  tibble(
    minute = as.integer(c(script_minutes, deltas$minute[delta_rows])),
    order = c(seq_along(script_rows) - 1L, 1000L + seq_along(delta_rows) - 1L),
    row = c(script_rows, delta_rows),
    is_delta = c(rep(FALSE, length(script_rows)), rep(TRUE, length(delta_rows)))
  ) |>
    arrange(minute, order)
}

# Runs a plan, and if the random draws broke one of its promises (a product
# that must end in good health ran out, say), orders earlier or adds a sale
# and runs it again. Every attempt replays the same draws, so the result is
# always the same.
settle_product <- function(plan, seed, fix_seed, seasons,
                           snapshots = integer(), max_fixes = 24) {
  fixes <- empty_fixes()
  fix_rng <- new_splitmix64(fix_seed)
  attempts <- integer()
  run <- simulate_product(plan, seed, seasons, fixes, snapshots)
  for (attempt in seq_len(max_fixes)) {
    failure <- check_run(run, plan)
    if (is.null(failure)) {
      break
    }
    if (failure$kind == "short_of_stock") {
      key <- as.character(failure$day)
      tried <- if (is.na(attempts[key])) 0L else attempts[key]
      attempts[key] <- tried + 1L
      order_day <- failure$day - 11L - 7L * tried
      if (order_day < plan$open_day) {
        break
      }
      fixes$forced_orders <- union(fixes$forced_orders, order_day)
    } else {
      last <- end_day - 12L
      window_start <- end_day - rate_window_days + 1L
      if (window_start > last) {
        break
      }
      day <- pick_day(window_start:last, plan$product, seasons, fix_rng)
      if (is.na(day)) {
        break
      }
      fixes$keep_alive_days <- union(fixes$keep_alive_days, day)
    }
    run <- simulate_product(plan, seed, seasons, fixes, snapshots)
  }
  run$failure <- check_run(run, plan)
  run
}

# The first promise a run breaks, or NULL.
check_run <- function(run, plan) {
  if (!is.null(run$failure)) {
    return(run$failure)
  }
  if (!is.null(plan$floor) && length(run$closing) > 0) {
    first <- max(plan$floor$from, run$first_day)
    if (first <= end_day) {
      days <- first:end_day
      below <- days[run$closing[days - run$first_day + 1] < plan$floor$units]
      if (length(below) > 0) {
        return(list(kind = "short_of_stock", day = below[1]))
      }
    }
  }
  if (plan$min_net_sold == 0 && !plan$must_end_healthy) {
    return(NULL)
  }
  window <- rate_window(run)
  if (window$net_sold < plan$min_net_sold) {
    day <- if (is.null(plan$sell_down)) end_day else plan$sell_down$from
    return(list(kind = "short_of_stock", day = day))
  }
  if (!plan$must_end_healthy) {
    return(NULL)
  }
  status <- stock_status(window)
  if (status == "healthy") {
    return(NULL)
  }
  if (status == "not_selling") {
    return(list(kind = "not_selling", day = NA_integer_))
  }
  list(kind = "short_of_stock", day = end_day)
}

# The last 90 days of a run, which the app's "needs attention" rules read.
rate_window <- function(run, last = end_day) {
  start <- last - rate_window_days + 1L
  days <- start:last
  kept <- days >= run$first_day & days - run$first_day < length(run$closing)
  closing <- integer(length(days))
  closing[kept] <- run$closing[days[kept] - run$first_day + 1]
  in_window <- run$movements |>
    filter(day >= start)
  sold <- tabulate_days(in_window, "sold", start, -1L)
  returned <- tabulate_days(in_window, "returned", start, 1L)
  first_movement <- if (nrow(run$movements) > 0) {
    min(run$movements$day)
  } else {
    last
  }
  list(
    closing = closing,
    sold = sold,
    returned = returned,
    net_sold = sum(sold) - sum(returned),
    on_hand = run$on_hand,
    days_since_first_movement = last - first_movement
  )
}

tabulate_days <- function(movements, kind, start, sign) {
  totals <- integer(rate_window_days)
  of_kind <- movements[movements$kind == kind, ]
  for (i in seq_len(nrow(of_kind))) {
    slot <- of_kind$day[i] - start + 1
    totals[slot] <- totals[slot] + sign * of_kind$quantity[i]
  }
  totals
}

# A product's state at the end of the window, by the app's rules (the first
# rule that matches wins).
stock_status <- function(window) {
  exposure_days <- sum(window$closing > 0 | window$sold > 0)
  daily_rate <- if (window$net_sold > 0) {
    window$net_sold / max(exposure_days, 14)
  } else {
    NA
  }
  cover <- if (window$on_hand > 0 && !is.na(daily_rate)) {
    window$on_hand / daily_rate
  } else {
    NA
  }
  if (window$on_hand < 0) {
    return("below_zero")
  }
  if (window$on_hand == 0) {
    return(if (window$net_sold > 0) "out_still_selling" else "out")
  }
  if (window$days_since_first_movement < 30) {
    return("new")
  }
  if (!is.na(cover) && cover < supplier_lead_time) {
    return("low")
  }
  if (window$days_since_first_movement >= 90 && !any(window$sold > 0)) {
    return("not_selling")
  }
  "healthy"
}
