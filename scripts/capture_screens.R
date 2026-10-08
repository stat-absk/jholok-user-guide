# Takes the guide's screenshots of the app, from the list in screens.csv.
#
# Every screen shows a throwaway in-memory demo shop, so no real stock is ever
# shown. A screen is reached one of two ways (the `arguments` column):
# - launch arguments, which open it straight away (the app's DEBUG
#   `DebugLaunch`);
# - "ui test: <name>", for a sheet reached by a tap or the lower part of a long
#   screen: the app's UI test JholokUITests/GuideScreenshotsUITests taps its
#   way there and saves the picture.
#
# Run it from the guide's folder with the iPhone 17 Pro simulator booted and a
# DEBUG build of the app installed:
#
#   Rscript scripts/capture_screens.R            # every screen
#   Rscript scripts/capture_screens.R review     # screens whose file matches

library(dplyr)
library(readr)
source("R/guide_settings.R")
source("R/shop_calendar.R")
source("R/simulate_shop.R")

bundle_id <- "com.abhishekbhattacharjee.jholok"
out_dir <- "images/app"
# Shown at 320 points wide in the guide, so 640 pixels keeps them sharp.
saved_width <- 640

simctl <- function(...) {
  status <- system2("xcrun", c("simctl", ...), stdout = FALSE, stderr = FALSE)
  if (status != 0) {
    stop("simctl ", paste(...), " failed", call. = FALSE)
  }
}

# The same moment on every picture: a full battery, full signal, 9:41.
prepare_simulator <- function() {
  simctl("ui", "booted", "appearance", "light")
  simctl(
    "status_bar", "booted", "override",
    "--time", "9:41",
    "--batteryState", "charged", "--batteryLevel", "100",
    "--cellularMode", "active", "--cellularBars", "4",
    "--wifiBars", "3"
  )
}

capture_screen <- function(file, arguments, wait_seconds) {
  system2("xcrun", c("simctl", "terminate", "booted", bundle_id),
    stdout = FALSE, stderr = FALSE
  )
  simctl("launch", "booted", bundle_id, strsplit(arguments, " ")[[1]])
  Sys.sleep(wait_seconds)
  full_size <- tempfile(fileext = ".png")
  simctl("io", "booted", "screenshot", "--type=png", full_size)
  resize_into_guide(full_size, file)
}

# The demo moves its story to end near today, so the screenshots only match
# the guide's shop when `screens_taken_on` falls in the same week as today.
check_story_date <- function(today = Sys.Date()) {
  if (story_shift(today) != story_shift(screens_taken_on)) {
    stop(
      "Today's screenshots would show the demo ", story_shift(today),
      " days on, but the guide's shop is set to ", screens_taken_on,
      ". Set `screens_taken_on` in R/guide_settings.R to ", today,
      " first.",
      call. = FALSE
    )
  }
}

ui_test_prefix <- "ui test: "

capture_screens <- function(pattern = NULL) {
  check_story_date()
  screens <- read_csv("scripts/screens.csv", show_col_types = FALSE)
  if (!is.null(pattern)) {
    screens <- filter(screens, grepl(pattern, file))
  }
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  prepare_simulator()
  launched <- filter(screens, !startsWith(arguments, ui_test_prefix))
  for (i in seq_len(nrow(launched))) {
    capture_screen(
      launched$file[i],
      launched$arguments[i],
      launched$wait_seconds[i]
    )
  }
  tapped <- filter(screens, startsWith(arguments, ui_test_prefix))
  if (nrow(tapped) > 0) {
    capture_by_ui_test(tapped)
  }
  if (is.null(pattern) || grepl(pattern, "report")) {
    capture_report()
  }
  system2("xcrun", c("simctl", "status_bar", "booted", "clear"))
  invisible(screens)
}

# Runs only the UI tests these screens need, which save their pictures to a
# temporary folder, then resizes each into the guide.
capture_by_ui_test <- function(screens) {
  folder <- tempfile("guide-screens-")
  dir.create(folder)
  tests <- unique(sub(ui_test_prefix, "", screens$arguments, fixed = TRUE))
  only <- paste0(
    "-only-testing:JholokUITests/GuideScreenshotsUITests/", tests
  )
  message("Running ", length(tests), " UI tests; this takes a few minutes")
  status <- withr::with_envvar(
    c(TEST_RUNNER_GUIDE_SCREENSHOTS_DIR = folder),
    system2(
      "xcodebuild",
      c(
        "test", "-quiet",
        "-project", "../Jholok.xcodeproj",
        "-scheme", "Jholok",
        "-destination", shQuote("platform=iOS Simulator,name=iPhone 17 Pro"),
        only
      )
    )
  )
  if (status != 0) {
    warning("Some UI tests failed; their screens are missing", call. = FALSE)
  }
  for (file in screens$file) {
    taken <- file.path(folder, file)
    if (!file.exists(taken)) {
      warning("No picture for ", file, call. = FALSE)
      next
    }
    resize_into_guide(taken, file)
  }
}

# The count report: `-report` makes the app write the latest completed demo
# count's report (Report.pdf) to its temporary folder. Ghostscript turns each
# A4 page into a picture.
report_dir <- "images/report"

capture_report <- function() {
  system2("xcrun", c("simctl", "terminate", "booted", bundle_id),
    stdout = FALSE, stderr = FALSE
  )
  simctl("launch", "booted", bundle_id, "-demo", "-report")
  Sys.sleep(12)
  container <- system2(
    "xcrun",
    c("simctl", "get_app_container", "booted", bundle_id, "data"),
    stdout = TRUE
  )
  report <- file.path(container, "tmp", "Report.pdf")
  if (!file.exists(report)) {
    stop("The app didn't write Report.pdf", call. = FALSE)
  }
  dir.create(report_dir, showWarnings = FALSE)
  unlink(list.files(report_dir, full.names = TRUE))
  status <- system2(
    "gs",
    c(
      "-q", "-dNOPAUSE", "-dBATCH", "-sDEVICE=png16m", "-r110",
      "-o", file.path(report_dir, "report-%d.png"), report
    )
  )
  if (status != 0) {
    stop("Couldn't turn the report into pictures", call. = FALSE)
  }
  message("Saved ", length(list.files(report_dir)), " report pages")
}

resize_into_guide <- function(full_size, file) {
  status <- system2(
    "sips",
    c(
      "--resampleWidth", saved_width, full_size,
      "--out", file.path(out_dir, file)
    ),
    stdout = FALSE
  )
  if (status != 0) {
    stop("Couldn't resize ", file, call. = FALSE)
  }
  message("Saved ", file)
}

if (sys.nframe() == 0) {
  pattern <- commandArgs(trailingOnly = TRUE)
  capture_screens(if (length(pattern) > 0) pattern[1] else NULL)
}
