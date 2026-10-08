# Numbers written the way the app writes them, so a figure in the guide reads
# like the same figure on the phone (JholokDomain: `IndianMoney`,
# `InsightSentences`, `CountUnit`).

minus_sign <- "−"
no_break_space <- " "

# Indian grouping: 1,23,45,678.
group_indian <- function(whole) {
  digits <- format(whole, scientific = FALSE, trim = TRUE)
  vapply(digits, group_one, "", USE.NAMES = FALSE)
}

group_one <- function(digits) {
  if (nchar(digits) <= 3) {
    return(digits)
  }
  head <- substr(digits, 1, nchar(digits) - 3)
  tail <- substr(digits, nchar(digits) - 2, nchar(digits))
  pairs <- character()
  while (nchar(head) > 2) {
    pairs <- c(substr(head, nchar(head) - 1, nchar(head)), pairs)
    head <- substr(head, 1, nchar(head) - 2)
  }
  paste(c(head, pairs, tail), collapse = ",")
}

# Rounds halves away from zero, as the app does with money.
round_plain <- function(x, digits = 0) {
  sign(x) * floor(abs(x) * 10^digits + 0.5) / 10^digits
}

# "₹1,16,640": every rupee, as on a product's page.
rupees <- function(amount) {
  sign <- if_else(amount < 0, minus_sign, "")
  paste0(sign, "₹", group_indian(round_plain(abs(amount))))
}

# "₹86,400", "₹1.14 L", "₹38.4 L", "₹2.60 Cr": three figures in lakh or crore
# from ₹1,00,000, as on the Overview.
rupees_short <- function(amount) {
  vapply(amount, rupees_short_one, "", USE.NAMES = FALSE)
}

rupees_short_one <- function(amount) {
  if (is.na(amount)) {
    return(NA_character_)
  }
  sign <- if (amount < 0) minus_sign else ""
  value <- abs(amount)
  if (round_plain(value) < 1e5) {
    return(paste0(sign, "₹", group_indian(round_plain(value))))
  }
  lakh <- three_figures(value / 1e5)
  if (lakh < 100) {
    number <- lakh
    unit <- "L"
  } else {
    number <- three_figures(value / 1e7)
    unit <- "Cr"
  }
  decimals <- if (number < 10) 2 else if (number < 100) 1 else 0
  shown <- formatC(number, format = "f", digits = decimals, big.mark = ",")
  paste0(sign, "₹", shown, no_break_space, unit)
}

three_figures <- function(value) {
  decimals_for <- \(x) if (x < 10) 2 else if (x < 100) 1 else 0
  first <- round_plain(value, decimals_for(value))
  round_plain(value, decimals_for(first))
}

# "3 pairs", "1 set", "12 pieces". A count is never added across units: pairs
# of earrings and sets are different things.
describe_units <- function(quantity, unit) {
  plural <- c(pair = "pairs", set = "sets", piece = "pieces")
  word <- if_else(abs(quantity) == 1, unit, unname(plural[unit]))
  paste(quantity, word)
}

# "a", "a and b", "a, b and c".
list_words <- function(items) {
  if (length(items) <= 1) {
    return(paste(items, collapse = ""))
  }
  paste(
    paste(items[-length(items)], collapse = ", "),
    items[length(items)],
    sep = " and "
  )
}

# "85%" from 10 on, "3 of 4" under it: a percentage of fewer than 10 things
# says more than it knows.
minimum_for_percent <- 10L

share <- function(part, whole) {
  case_when(
    whole <= 0 ~ NA_character_,
    whole < minimum_for_percent ~ paste(part, "of", whole),
    .default = percent_words(part / whole)
  )
}

percent_words <- function(ratio) {
  value <- abs(ratio) * 100
  case_when(
    value == 0 ~ "0%",
    value < 1 ~ "under 1%",
    .default = paste0(round_plain(value), "%")
  )
}

# "26 Sep", "26 September", "26 Sep 2026, 10:00": the day without a leading
# zero, as the app writes dates. `rest` is the format after the day.
date_words <- function(date, rest = "%b") {
  day <- as.integer(format(date, "%d", tz = shop_time_zone))
  paste(day, format(date, rest, tz = shop_time_zone))
}

# A movement's kind as the app names it.
movement_names <- c(
  opening = "Opening stock",
  received = "Received",
  sold = "Sold",
  returned = "Returned",
  adjustment = "Adjustment",
  count_adjustment = "Count adjustment",
  sent_out = "Sent out",
  came_back = "Back in"
)

movement_name <- function(kind) {
  unname(movement_names[kind])
}
