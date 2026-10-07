# The tests run the same code the chapters do.
library(dplyr)
library(tibble)
r_files <- list.files(here::here("R"), pattern = "\\.R$", full.names = TRUE)
invisible(lapply(r_files, source))

shop <- load_shop()
