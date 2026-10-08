# Stock sent out of the shop for a while: on jangad, with the karigar, or kept
# for a customer's order (Jholok/DevTools/DemoStockStates.swift).
#
# Each send-out is a pair of "sent out" movements that add up to zero: minus
# n at the shop and plus n at the place. So the stock the shop owns doesn't
# change, but the stock in the shop, which a count expects on the shelf, goes
# down.
#
# The app sends these when it starts, timed back from that moment, and skips
# products an open count covers. `sent_from` stands in for that moment: the
# guide uses late afternoon on the day the screenshots were taken.

stock_out_story <- tribble(
  ~type, ~at_least, ~units, ~place, ~party, ~memo, ~days_before, ~due_in,
  ~signed_by,
  "Earrings", 3L, 2L, "jangad", "Sharma Jewellers", "41", 2, 5, "Sita",
  "Necklaces", 2L, 1L, "karigar", "Ramesh karigar", "K-17", 45, -15, "Bidisha",
  "Sets", 2L, 1L, "order", "Mrs Banerjee", "O-208", 3, NA, "Sita"
)

add_stock_out <- function(shop, sent_from) {
  open_types <- shop$counts |>
    filter(is.na(completed_at)) |>
    pull(scope) |>
    unlist()
  in_shop <- stock_in_shop(shop, sent_from)
  last_counted <- shop$count_lines |>
    inner_join(
      filter(shop$counts, !is.na(completed_at)),
      by = "count_id"
    ) |>
    summarise(last_count = max(completed_at), .by = sku)

  candidates <- shop$products |>
    filter(is.na(archived_at), !type %in% open_types) |>
    left_join(in_shop, by = "sku") |>
    left_join(last_counted, by = "sku") |>
    arrange(sku)

  sends <- purrr::pmap(stock_out_story, \(type, at_least, units, place, party,
                                          memo, days_before, due_in,
                                          signed_by) {
    sent_at <- sent_from - days_before * 86400
    picked <- candidates |>
      filter(
        .data$type == .env$type,
        in_shop >= at_least,
        is.na(last_count) | last_count < sent_at
      ) |>
      slice_head(n = 1)
    if (nrow(picked) == 0) {
      return(NULL)
    }
    tibble(
      sku = picked$sku, place, units, party, memo, sent_at,
      due_back = sent_from + due_in * 86400, signed_by
    )
  }) |>
    purrr::list_rbind()

  pairs <- bind_rows(
    transmute(sends, sku, date = sent_at, place = NA_character_,
              quantity = -units),
    transmute(sends, sku, date = sent_at, place, quantity = units)
  ) |>
    mutate(
      kind = "sent_out",
      note = paste("Memo", sends$memo[match(sku, sends$sku)])
    )

  shop$movements <- bind_rows(shop$movements, pairs) |>
    arrange(date)
  shop$out_records <- sends
  shop
}

# Stock in the shop itself: what a count expects to find on the shelf.
stock_in_shop <- function(shop, at = shop$end_at) {
  moves <- shop$movements
  if (!"place" %in% names(moves)) {
    moves$place <- NA_character_
  }
  moves |>
    filter(date <= at, is.na(place)) |>
    summarise(in_shop = sum(quantity), .by = sku) |>
    right_join(select(shop$products, sku), by = "sku") |>
    mutate(in_shop = coalesce(in_shop, 0L))
}
