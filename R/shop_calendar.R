# The demo shop's calendar: open days, busy weekends and the festival and
# wedding seasons (JholokKit/Sources/JholokDemo/DemoCalendar.swift).
#
# The simulation counts days from Sunday 1 June 2025 (day 0). The story ends on
# Thursday 24 September 2026 at 18:00, day 480.

first_day <- as.Date("2025-06-01")

as_day <- function(date) {
  as.integer(as.Date(date) - first_day)
}

end_day <- as_day("2026-09-24")
end_minute <- 18 * 60

# 1 is Sunday and 7 is Saturday.
weekday_number <- function(day) {
  (day %% 7) + 1L
}

# The shop closes on Tuesdays.
is_open <- function(day) {
  weekday_number(day) != 3L
}

# Sundays and Saturdays are busier than weekdays.
weekday_factor <- function(day) {
  factors <- c(1.4, 1, 0, 1, 1, 1, 1.3)
  factors[weekday_number(day)]
}

# How much busier each season is than an ordinary week, for each profile.
# A blank (NA) uses `other`. Later rows win where seasons overlap, as Dhanteras
# sits inside the Diwali run-up.
shop_seasons <- function() {
  tribble(
    ~season, ~first, ~last, ~festive, ~bridal, ~everyday, ~coin, ~other,
    "Summer weddings", "2025-06-01", "2025-07-05", NA, 1.4, NA, NA, 1.0,
    "Chaturmas", "2025-07-06", "2025-09-21", 0.9, 0.35, 0.8, 0.8, 0.8,
    "Raksha Bandhan", "2025-08-05", "2025-08-09", 1.8, NA, NA, NA, 1.3,
    "Ganesh Chaturthi", "2025-08-25", "2025-08-28", 1.5, NA, NA, 4, 1.2,
    "Pitru Paksha", "2025-09-07", "2025-09-21", 0.5, 0.3, 0.6, 0.5, 0.5,
    "Navratri", "2025-09-22", "2025-10-01", 1.8, 1.3, NA, 1.5, 1.2,
    "Dussehra", "2025-10-02", "2025-10-02", 2.5, NA, NA, 3, 1.5,
    "Karwa Chauth week", "2025-10-06", "2025-10-10", 1.5, 1.6, NA, NA, 1.3,
    "Dhanteras run-up", "2025-10-13", "2025-10-17", NA, NA, NA, 5, 2.0,
    "Dhanteras", "2025-10-18", "2025-10-18", 9, 4, 6, 45, 6,
    "Diwali", "2025-10-19", "2025-10-20", 2.5, NA, NA, 4, 2,
    "After Diwali", "2025-10-21", "2025-10-31", NA, NA, NA, NA, 0.8,
    "Wedding season", "2025-11-01", "2025-12-15", 1.1, 2.2, 1.2, NA, 1.0,
    "Kharmas", "2025-12-16", "2026-01-14", NA, 0.4, NA, NA, 0.8,
    "Wedding season", "2026-01-15", "2026-03-13", NA, 1.8, NA, NA, 1.1,
    "Kharmas", "2026-03-14", "2026-04-13", NA, 0.4, NA, NA, 0.85,
    "Gudi Padwa", "2026-03-19", "2026-03-19", 2, NA, NA, 4, 1.5,
    "Akshaya Tritiya run-up", "2026-04-14", "2026-04-18", NA, NA, NA, 1.5, 1.5,
    "Akshaya Tritiya", "2026-04-19", "2026-04-19", 6, 5, NA, 35, 5,
    "Summer weddings", "2026-04-20", "2026-05-16", NA, 2.0, NA, NA, 1.2,
    "Adhik Maas", "2026-05-17", "2026-06-15", NA, 0.5, NA, NA, 0.85,
    "Weddings resume", "2026-06-16", "2026-07-24", NA, 1.4, NA, NA, 1.0,
    "Chaturmas", "2026-07-25", "2026-09-24", 0.9, 0.35, 0.8, 0.8, 0.8,
    "Onam, Raksha Bandhan", "2026-08-24", "2026-08-28", 1.8, NA, NA, NA, 1.3,
    "Ganesh Chaturthi", "2026-09-12", "2026-09-15", 1.5, NA, NA, 6, 1.2
  ) |>
    mutate(first = as_day(first), last = as_day(last))
}

# Sales on these days carry the note "Festival".
festival_days <- as_day(c(
  "2025-08-09", "2025-08-27", "2025-10-02", "2025-10-10", "2025-10-18",
  "2025-10-20", "2026-03-19", "2026-04-19", "2026-08-26", "2026-08-28",
  "2026-09-14"
))

# A table of every day's multiplier for every profile, worked out once. Slow
# and dead products ignore the seasons.
season_multipliers <- function(days = 0:end_day) {
  seasons <- shop_seasons()
  profiles <- c("festive", "bridal", "everyday", "coin")
  table <- matrix(
    1,
    nrow = length(days),
    ncol = 6,
    dimnames = list(NULL, c(profiles, "slow", "dead"))
  )
  for (row in seq_len(nrow(seasons))) {
    season <- seasons[row, ]
    inside <- days >= season$first & days <= season$last
    for (profile in profiles) {
      value <- season[[profile]]
      table[inside, profile] <- if (is.na(value)) season$other else value
    }
  }
  table
}
