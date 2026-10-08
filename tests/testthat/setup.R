# The tests run the same code the chapters do.
library(dplyr)
library(tibble)
r_files <- list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

# The app's reference files are written for the story's own end date, so the
# tests use it, whatever day the screenshots were taken.
reference_end <- as.Date("2026-09-24")
shop <- load_shop(end_on = reference_end)
