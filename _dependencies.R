# Packages the guide needs that no chapter loads by name, so renv records
# them in renv.lock. This file is never run.

library(svglite) # charts are drawn as SVG (_quarto.yml)
library(gt) # tables
library(lintr) # style checks
library(styler) # tidyverse formatting
library(testthat) # tests of the simulated shop
library(readr) # the app's reference files in the tests
