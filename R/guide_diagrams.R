# Plain diagrams for ideas a photo or screenshot can't show well. Drawn with
# ggplot from shapes, in the app's colours, so they sit beside the charts.

diagram_ink <- guide_colours$text_primary
diagram_soft <- guide_colours$text_secondary

# A card with a pair of earrings on it, for the box diagrams.
earring_card <- function(x, y, id, size = 1) {
  half <- 0.4 * size
  list(
    card = tibble(id, xmin = x - half, xmax = x + half,
                  ymin = y - half, ymax = y + half),
    drops = tibble(
      id,
      x = x + c(-0.13, 0.13) * size,
      y = y + 0.02 * size
    )
  )
}

draw_cards <- function(cards) {
  card_rects <- purrr::map(cards, "card") |> purrr::list_rbind()
  drops <- purrr::map(cards, "drops") |> purrr::list_rbind()
  list(
    geom_rect(
      aes(xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax),
      data = card_rects,
      fill = guide_colours$surface_raised,
      colour = guide_colours$hairline
    ),
    geom_point(
      aes(x, y),
      data = drops,
      shape = 21,
      size = 4,
      stroke = 1,
      fill = guide_colours$gold_mid,
      colour = guide_colours$gold_deep
    )
  )
}

# Three cards: the app counts cards, one pair or set each; a card that may
# hold two is flagged for a person to decide; touching cards get a warning,
# never a guessed split.
diagram_cards_not_pieces <- function() {
  outline <- \(xmin, xmax, ymin, ymax, colour, dashed = FALSE) {
    annotate(
      "rect",
      xmin = xmin, xmax = xmax, ymin = ymin, ymax = ymax,
      fill = NA, colour = colour, linewidth = 1,
      linetype = if (dashed) "22" else "solid"
    )
  }
  badge <- \(x, y, text, colour) {
    annotate(
      "label",
      x = x, y = y, label = text,
      fill = colour, colour = "white", fontface = "bold", size = 3.4,
      linewidth = 0
    )
  }
  caption <- \(x, text) {
    annotate(
      "text",
      x = x, y = -0.85, label = text,
      colour = diagram_ink, size = 3.6, lineheight = 0.95, vjust = 1
    )
  }

  one_pair <- earring_card(0, 0, "one")
  two_pairs <- list(
    earring_card(3.1, 0.17, "first", size = 0.8),
    earring_card(3.5, -0.17, "second", size = 0.8)
  )
  touching <- list(
    earring_card(6.1, 0, "left", size = 0.9),
    earring_card(6.85, 0, "right", size = 0.9)
  )

  ggplot() +
    draw_cards(c(list(one_pair), two_pairs, touching)) +
    outline(-0.48, 0.48, -0.48, 0.48, diagram_ink) +
    badge(-0.48, 0.48, "1", diagram_ink) +
    outline(2.7, 3.9, -0.55, 0.55, guide_colours$gold_deep) +
    badge(3.9, 0.55, "Make it 2?", guide_colours$gold_deep) +
    outline(5.65, 7.3, -0.47, 0.47, guide_colours$ruby, dashed = TRUE) +
    badge(7.3, 0.47, "!", guide_colours$ruby) +
    caption(0, "One card holds one pair:\nthe app counts 1 pair.") +
    caption(
      3.3,
      "This may be two cards:\nyou decide, the app\nnever splits it."
    ) +
    caption(6.5, "Touching cards:\nthe app warns,\nand never guesses.") +
    coord_fixed(xlim = c(-0.9, 7.8), ylim = c(-2, 0.9)) +
    theme_void()
}

# One product's year as the ledger keeps it: every kind of movement added
# together gives the stock on hand. No number is typed in.
diagram_ledger <- function(shop, product_sku) {
  # In the order a year's stock builds up, then goes out.
  kinds <- c(
    opening = "Opening stock",
    received = "Received",
    returned = "Returned",
    sold = "Sold",
    adjustment = "Adjustments",
    count_adjustment = "Count adjustments"
  )
  steps <- shop$movements |>
    filter(sku == product_sku) |>
    summarise(change = sum(quantity), .by = kind) |>
    mutate(kind = factor(kind, levels = names(kinds))) |>
    arrange(kind) |>
    mutate(
      label = kinds[as.character(kind)],
      end = cumsum(change),
      start = lag(end, default = 0)
    )
  on_hand <- tibble(
    label = "On hand",
    start = 0,
    end = sum(steps$change),
    change = sum(steps$change)
  )
  bars <- bind_rows(steps, on_hand) |>
    mutate(
      position = row_number(),
      label = factor(label, levels = label),
      direction = case_when(
        label == "On hand" ~ "total",
        change < 0 ~ "out",
        .default = "in"
      ),
      text = if_else(
        direction == "total",
        as.character(change),
        # The app's minus sign, not a hyphen.
        sub("-", minus_sign, sprintf("%+d", change), fixed = TRUE)
      )
    )

  ggplot(bars) +
    geom_rect(
      aes(
        xmin = position - 0.38, xmax = position + 0.38,
        ymin = start, ymax = end, fill = direction
      )
    ) +
    geom_segment(
      aes(
        x = position + 0.38, xend = position + 0.62,
        y = end, yend = end
      ),
      data = filter(bars, direction != "total"),
      colour = diagram_soft,
      linewidth = 0.3
    ) +
    geom_text(
      aes(position, pmax(start, end), label = text),
      vjust = -0.5,
      colour = diagram_ink,
      size = 3.6
    ) +
    scale_fill_manual(
      values = c(
        `in` = guide_colours$jade,
        out = guide_colours$ruby,
        total = guide_colours$gold_deep
      ),
      guide = "none"
    ) +
    scale_x_continuous(
      breaks = bars$position,
      labels = bars$label
    ) +
    scale_y_continuous(expand = expansion(mult = c(0, 0.12))) +
    labs(x = NULL, y = NULL) +
    theme_guide() +
    theme(axis.text.y = element_blank(), panel.grid.major.y = element_blank())
}

# The life of a count: counted blind, submitted, reviewed by someone who
# didn't count, then completed. Review can send it back for more counting.
diagram_count_life <- function() {
  steps <- tibble(
    step = c("Start", "Count", "Submit", "Review", "Complete"),
    who = c(
      "anyone in People,\nwho then counts", "counters, blind", "a counter",
      "an approver who\ndidn't count", "the approver signs"
    ),
    x = c(0, 2.2, 4.4, 6.6, 8.8)
  )
  arrows <- tibble(
    x = head(steps$x, -1) + 0.75,
    xend = tail(steps$x, -1) - 0.75
  )

  ggplot(steps) +
    geom_segment(
      aes(x = x, xend = xend, y = 0, yend = 0),
      data = arrows,
      colour = diagram_soft,
      arrow = grid::arrow(length = grid::unit(0.18, "cm"), type = "closed")
    ) +
    annotate(
      "curve",
      x = 6.6, xend = 2.2, y = 0.35, yend = 0.35,
      curvature = 0.35,
      colour = diagram_soft,
      linetype = "22",
      arrow = grid::arrow(length = grid::unit(0.18, "cm"), type = "closed")
    ) +
    annotate(
      "text",
      x = 4.4, y = 1.25, label = "Reopen, with a reason",
      colour = diagram_soft, size = 3.4
    ) +
    geom_label(
      aes(x, 0, label = step),
      fill = guide_colours$surface_raised,
      colour = diagram_ink,
      fontface = "bold",
      size = 4,
      label.r = grid::unit(0.4, "lines"),
      label.padding = grid::unit(0.5, "lines"),
      linewidth = 0.3
    ) +
    geom_text(
      aes(x, -0.55, label = who),
      colour = diagram_soft,
      size = 3.2,
      lineheight = 0.95,
      vjust = 1
    ) +
    coord_cartesian(xlim = c(-0.8, 9.6), ylim = c(-1.4, 1.5)) +
    theme_void()
}

# Where stock can be. The shop's own stock is what a count checks; pieces
# out with the karigar, on jangad or kept for an order are still owned.
diagram_places <- function() {
  places <- tibble(
    place = c("The shop", "Jangad", "Karigar", "Order"),
    detail = c(
      "what a count checks",
      "out on approval, with a memo,\nusually back in 7 days",
      "with the craftsman,\nusually back in 30 days",
      "set aside for a\ncustomer's order"
    ),
    x = c(0, 3.4, 3.4, 3.4),
    y = c(0, 1.5, 0, -1.5)
  )
  links <- filter(places, place != "The shop")

  ggplot(places) +
    geom_segment(
      aes(x = 0.95, xend = x - 0.85, y = 0.06, yend = y + 0.06),
      data = links,
      colour = diagram_soft,
      arrow = grid::arrow(length = grid::unit(0.16, "cm"), type = "closed")
    ) +
    geom_segment(
      aes(x = x - 0.85, xend = 0.95, y = y - 0.12, yend = -0.12),
      data = links,
      colour = guide_colours$hairline,
      linetype = "22",
      arrow = grid::arrow(length = grid::unit(0.16, "cm"), type = "closed")
    ) +
    annotate(
      "text",
      x = 1.75, y = 1.3, label = "Sent out", colour = diagram_soft,
      size = 3.2, angle = 24
    ) +
    annotate(
      "text",
      x = 1.75, y = -1.25, label = "Back in, or sold there",
      colour = diagram_soft,
      size = 3.2, angle = -24
    ) +
    geom_label(
      aes(x, y, label = place),
      fill = guide_colours$surface_raised,
      colour = diagram_ink,
      fontface = "bold",
      size = 4,
      label.r = grid::unit(0.4, "lines"),
      label.padding = grid::unit(0.5, "lines"),
      linewidth = 0.3
    ) +
    geom_text(
      aes(x, y - 0.42, label = detail),
      colour = diagram_soft,
      size = 3.1,
      lineheight = 0.95,
      vjust = 1
    ) +
    coord_cartesian(xlim = c(-1, 4.6), ylim = c(-2.4, 2)) +
    theme_void()
}
