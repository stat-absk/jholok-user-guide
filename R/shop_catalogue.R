# The catalogue of Jholok Jewellers, the made-up shop in the app's demo
# (JholokKit/Sources/JholokDemo/DemoCatalogue.swift, docs/design/demo-data.md).
#
# Prices follow the demo's price basis (22K gold at ₹13,500 a gram, and so on).
# Each product's weight is part of its variant text, as in the app.

# How the app counts each type: earrings in pairs, sets as one, the rest as
# pieces.
shop_types <- function() {
  tribble(
    ~type, ~unit, ~sort_order,
    "Earrings", "pair", 0L,
    "Rings", "piece", 1L,
    "Necklaces", "piece", 2L,
    "Bangles", "piece", 3L,
    "Sets", "set", 4L,
    "Coins", "piece", 5L,
    "Other", "piece", 6L
  )
}

# One row per product. `base_per_week` is how many it sells in an ordinary week
# before the seasons; `profile` says which seasons move it:
# - festive: Navratri, Dhanteras, Diwali
# - bridal: the wedding seasons
# - everyday: steady sellers
# - coin: gold coins on auspicious days
# - slow, dead: sell only when the story says so, or never
shop_catalogue <- function() {
  products <- tribble(
    ~sku, ~type, ~name, ~variant, ~cost, ~price, ~opening,
    ~base_per_week, ~profile, ~restocks,
    "EAR-0001", "Earrings", "Jhumka", "Antique, 22K, 8 g",
    116640, 131300, 6, 0.45, "festive", TRUE,
    "EAR-0002", "Earrings", "Jhumka", "Temple Lakshmi, 22K, 14 g",
    206010, 233600, 3, 0.15, "bridal", TRUE,
    "EAR-0003", "Earrings", "Chandbali", "Kundan, 22K, 12 g",
    184200, 211900, 4, 0.30, "festive", TRUE,
    "EAR-0004", "Earrings", "Stud", "Plain, 22K, 3 g",
    43340, 48000, 12, 1.10, "everyday", TRUE,
    "EAR-0005", "Earrings", "Stud", "Diamond flower, 18K, 0.20 ct",
    41870, 51900, 5, 0.30, "everyday", TRUE,
    "EAR-0006", "Earrings", "Hoop", "Hammered, 22K, 15 mm, 4 g",
    57780, 64000, 8, 0.45, "everyday", TRUE,
    "EAR-0007", "Earrings", "Drop", "Pearl, 22K, 5 g",
    74400, 84100, 4, 0.15, "everyday", TRUE,
    "EAR-0008", "Earrings", "Ear cuff", "Filigree, 22K, 6 g",
    88290, 100100, 3, 0, "slow", TRUE,
    "RIN-0001", "Rings", "Band", "Plain, 22K, 4 g",
    57240, 63400, 15, 0.80, "bridal", TRUE,
    "RIN-0002", "Rings", "Band", "Men's, 22K, 8 g",
    114480, 126800, 6, 0.30, "bridal", TRUE,
    "RIN-0003", "Rings", "Solitaire", "18K, 0.30 ct",
    74840, 96100, 3, 0.12, "bridal", TRUE,
    "RIN-0004", "Rings", "Cocktail ring", "Ruby, 22K, 7 g",
    111010, 127900, 3, 0.10, "festive", TRUE,
    "RIN-0005", "Rings", "Navratna ring", "22K, 6 g",
    93290, 107100, 3, 0.08, "festive", TRUE,
    "NEC-0001", "Necklaces", "Chain", "Rope, 22K, 18 in, 10 g",
    141750, 155700, 10, 0.60, "everyday", TRUE,
    "NEC-0002", "Necklaces", "Chain", "Box link, 22K, 20 in, 15 g",
    212620, 233600, 6, 0.25, "everyday", TRUE,
    "NEC-0003", "Necklaces", "Pendant", "Lakshmi, 22K, 4 g",
    58320, 65600, 8, 0.40, "festive", TRUE,
    "NEC-0004", "Necklaces", "Pendant", "Diamond heart, 18K",
    38870, 47700, 4, 0.20, "everyday", TRUE,
    "NEC-0005", "Necklaces", "Mangalsutra", "Short, black beads, 22K, 10 g",
    144450, 161300, 6, 0.50, "bridal", TRUE,
    "NEC-0006", "Necklaces", "Mangalsutra", "Long, 22K, 20 g",
    288900, 322600, 3, 0.15, "bridal", TRUE,
    "NEC-0007", "Necklaces", "Choker", "Antique, rubies, 22K, 35 g",
    534750, 614600, 3, 0.10, "bridal", TRUE,
    "NEC-0008", "Necklaces", "Temple necklace", "Lakshmi coin, 22K, 45 g",
    668250, 763400, 2, 0, "slow", TRUE,
    "NEC-0009", "Necklaces", "Rani haar", "22K, 60 g",
    891000, 1017800, 2, 0, "dead", TRUE,
    "BAN-0001", "Bangles", "Bangle", "Plain, 22K, size 2.4, 12 g",
    171720, 188600, 16, 0.80, "bridal", TRUE,
    "BAN-0002", "Bangles", "Bangle", "Carved, 22K, size 2.6, 15 g",
    214650, 235700, 10, 0.40, "bridal", TRUE,
    "BAN-0003", "Bangles", "Kada", "Men's, 22K, 25 g",
    361120, 399800, 3, 0.10, "everyday", TRUE,
    "BAN-0004", "Bangles", "Kada", "Antique, 22K, 30 g",
    441450, 500600, 2, 0, "slow", TRUE,
    "BAN-0005", "Bangles", "Bracelet", "Ladies' chain, 22K, 8 g",
    115560, 129000, 6, 0.30, "festive", TRUE,
    "BAN-0006", "Bangles", "Bracelet", "Men's, 22K, 18 g",
    260010, 287800, 3, 0.12, "festive", TRUE,
    "BAN-0007", "Bangles", "Bangle", "Meenakari, 22K, size 2.4, 10 g",
    144450, 161300, 6, 0.30, "bridal", FALSE,
    "SET-0001", "Sets", "Bridal set", "Kundan necklace and jhumkas, 22K, 85 g",
    1302250, 1497600, 2, 0.06, "bridal", TRUE,
    "SET-0002", "Sets", "Temple set", "Necklace and jhumkas, 22K, 60 g",
    891000, 1017800, 2, 0.08, "bridal", TRUE,
    "SET-0003", "Sets", "Light set", "Necklace and studs, 22K, 18 g",
    262440, 295300, 6, 0.35, "festive", TRUE,
    "SET-0004", "Sets", "Bangle set", "Four bangles, 22K, 40 g",
    577800, 645200, 3, 0.10, "bridal", TRUE,
    "SET-0005", "Sets", "Choker set", "Polki choker and studs, 22K, 45 g",
    728250, 846800, 1, 0.04, "bridal", TRUE,
    "SET-0006", "Sets", "Necklace set", "Festive lightweight, 22K, 16 g",
    228960, 253600, 4, 0.30, "festive", TRUE,
    "COI-0001", "Coins", "Coin", "Lakshmi, 24K, 1 g",
    15140, 16400, 20, 1.20, "coin", TRUE,
    "COI-0002", "Coins", "Coin", "24K, 5 g",
    75700, 81000, 8, 0.20, "coin", TRUE,
    "COI-0003", "Coins", "Coin", "Lakshmi, 24K, 10 g",
    151410, 160500, 4, 0.10, "coin", TRUE,
    "COI-0004", "Coins", "Coin", "Silver 999, 10 g",
    2420, NA, 15, 0.40, "coin", TRUE,
    "OTH-0001", "Other", "Nose pin", "Diamond, 18K",
    9580, 12000, 12, 0.50, "everyday", TRUE,
    "OTH-0002", "Other", "Nath", "Maharashtrian pearl, 22K, 4 g",
    61360, 70200, 3, 0.08, "bridal", TRUE,
    "OTH-0003", "Other", "Maang tikka", "Kundan, 22K, 6 g",
    91290, 104300, 4, 0.15, "bridal", TRUE,
    "OTH-0004", "Other", "Waist chain", "Kamarbandh, 22K, 50 g",
    NA, 834300, 1, 0, "dead", FALSE
  )

  products |>
    mutate(
      opening = as.integer(opening),
      # The app scales every product's demand so stock turns about twice a
      # year, as an Indian jeweller's typically does.
      base_per_week = base_per_week * demand_scale,
      # Plain bangles sell in twos.
      sells_in_twos = sku == "BAN-0001",
      par = pmax(1L, round_half_up(opening * par_share)),
      supplier = supplier_for(type, name, variant)
    )
}

demand_scale <- 0.45

# The weekly top-up refills each product to three quarters of its opening
# stock.
par_share <- 0.75

# Swift's `rounded()` rounds halves away from zero; R's `round()` rounds them
# to even, which would give a different par for 6 × 0.75.
round_half_up <- function(x) {
  as.integer(floor(x + 0.5))
}

supplier_for <- function(type, name, variant) {
  text <- tolower(paste(name, variant))
  case_when(
    type == "Coins" ~ "Supplier: Mumbai Bullion",
    grepl("kundan|polki", text) ~ "Supplier: Kundan Kala",
    .default = "Supplier: Shree Gold Works"
  )
}
