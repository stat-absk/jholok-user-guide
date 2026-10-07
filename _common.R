# Run at the top of every chapter: the same packages, options and helpers, so
# every chapter tells the story of the same shop with the same numbers.

library(dplyr)
library(ggplot2)
library(tibble)

r_files <- list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

knitr::opts_chunk$set(
  comment = "#>",
  fig.retina = 2
)

# Large numbers in full, never as 1e+05.
options(scipen = 999)

# Jholok Jewellers, the same shop as the app's demo.
shop <- load_shop()
