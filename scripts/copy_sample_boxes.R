# Copies the app's three sample box photos into the guide, made smaller for
# the web, with their label files. Run it from the guide's folder whenever the
# app's sample boxes change (Jholok/DevTools/DemoBoxes/).
#
# The photos are not real: the app's tool `jholok-synth` drew them from the
# demo shop's own piece tags.

source_dir <- "../Jholok/DevTools/DemoBoxes"
out_dir <- "images/boxes"
# Long side in pixels: sharp at the guide's width, small enough to load fast.
long_side <- 1200

copy_sample_box <- function(number) {
  name <- paste0("demo-box-", number)
  photo <- file.path(source_dir, paste0(name, ".jpg"))
  copy <- file.path(out_dir, paste0(name, ".jpg"))
  status <- system2(
    "sips",
    c("-Z", long_side, photo, "--out", copy),
    stdout = FALSE
  )
  if (status != 0) {
    stop("Couldn't copy ", photo, call. = FALSE)
  }
  file.copy(
    file.path(source_dir, paste0(name, ".json")),
    out_dir,
    overwrite = TRUE
  )
  message("Copied ", name)
}

if (sys.nframe() == 0) {
  dir.create(out_dir, showWarnings = FALSE, recursive = TRUE)
  invisible(lapply(1:3, copy_sample_box))
}
