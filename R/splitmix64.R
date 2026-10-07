# SplitMix64, the random number generator behind the app's demo shop
# (JholokKit/Sources/JholokDemo/SplitMix64.swift).
#
# The app's demo draws every sale from this generator, so the guide's shop can
# only match the app's, sale for sale, if R draws exactly the same numbers. R
# has no unsigned 64-bit integers, so a 64-bit value is held as four 16-bit
# "limbs", least significant first. Every limb is a whole number below 65,536,
# which keeps all the arithmetic exact in R's doubles.

limb_base <- 65536

u64_from_hex <- function(hex) {
  digits <- sprintf("%016s", sub("^0x", "", tolower(hex)))
  digits <- gsub(" ", "0", digits)
  starts <- c(13, 9, 5, 1)
  strtoi(substring(digits, starts, starts + 3), base = 16L) |>
    as.numeric()
}

u64_add <- function(a, b) {
  sum_limbs <- a + b
  carry_limbs(sum_limbs)
}

# Keeps only the low 64 bits, as Swift's wrapping `&*` does.
u64_multiply <- function(a, b) {
  product <- numeric(4)
  for (i in 1:4) {
    for (j in 1:(5 - i)) {
      product[i + j - 1] <- product[i + j - 1] + a[i] * b[j]
    }
  }
  carry_limbs(product)
}

carry_limbs <- function(limbs) {
  for (i in 1:3) {
    carry <- limbs[i] %/% limb_base
    limbs[i] <- limbs[i] %% limb_base
    limbs[i + 1] <- limbs[i + 1] + carry
  }
  limbs[4] <- limbs[4] %% limb_base
  limbs
}

u64_xor <- function(a, b) {
  as.numeric(bitwXor(as.integer(a), as.integer(b)))
}

u64_shift_right <- function(a, bits) {
  whole_limbs <- bits %/% 16
  spare_bits <- bits %% 16
  moved <- c(a[(whole_limbs + 1):4], rep(0, whole_limbs))
  if (spare_bits == 0) {
    return(moved)
  }
  higher <- c(moved[-1], 0)
  moved %/% 2^spare_bits + (higher %% 2^spare_bits) * 2^(16 - spare_bits)
}

u64_to_double <- function(a) {
  sum(a * limb_base^(0:3))
}

# A generator whose whole output follows from its seed. It keeps its state, so
# each call to `next_u64()` moves it on, as the Swift struct's `mutating` calls
# do.
new_splitmix64 <- function(seed) {
  state <- seed
  golden_gamma <- u64_from_hex("9E3779B97F4A7C15")
  mix_1 <- u64_from_hex("BF58476D1CE4E5B9")
  mix_2 <- u64_from_hex("94D049BB133111EB")

  next_u64 <- function() {
    state <<- u64_add(state, golden_gamma)
    z <- state
    z <- u64_multiply(u64_xor(z, u64_shift_right(z, 30)), mix_1)
    z <- u64_multiply(u64_xor(z, u64_shift_right(z, 27)), mix_2)
    u64_xor(z, u64_shift_right(z, 31))
  }

  # A uniform value in [0, 1): the top 53 bits, as Swift's `nextUnit()`.
  next_unit <- function() {
    u64_to_double(u64_shift_right(next_u64(), 11)) * 2^-53
  }

  # Knuth's method, which suits the small daily means of a jewellery shop.
  poisson <- function(mean) {
    if (mean <= 0) {
      return(0L)
    }
    limit <- exp(-mean)
    count <- 0L
    product <- next_unit()
    while (product > limit) {
      count <- count + 1L
      product <- product * next_unit()
    }
    count
  }

  list(next_u64 = next_u64, next_unit = next_unit, poisson = poisson)
}
