# The app's three sample boxes (Jholok/DevTools/DemoBoxes/), read into tidy
# tables.
#
# Each photo has a label file. It gives the box's four corners on the photo,
# and each piece's outline in the straightened box: 0 to 1 across and down
# the box itself, as the app stores it. `pieces_on_photo()` turns those
# outlines back into the photo's own coordinates, so they can be drawn on it.
#
# The photos were drawn by the app's tool `jholok-synth` from the demo shop's
# piece tags; they are not photos of a real shop's boxes.

sample_box_numbers <- 1:3

sample_box_path <- function(number, extension) {
  here::here("images", "boxes", paste0("demo-box-", number, ".", extension))
}

read_label_file <- function(number) {
  jsonlite::read_json(sample_box_path(number, "json"))
}

# One row per box.
sample_boxes <- function() {
  purrr::map(sample_box_numbers, \(number) {
    label <- read_label_file(number)
    tibble(
      box = number,
      type = label$typeName,
      unit = label$unit,
      notes = label$notes,
      photo_width = label$photoSize$width,
      photo_height = label$photoSize$height,
      pieces = length(label$pieces),
      tags_read = sum(purrr::map_lgl(
        label$pieces,
        \(entry) isTRUE(entry$tagReadable) && !is.null(entry$tag)
      ))
    )
  }) |>
    purrr::list_rbind()
}

# One row per piece, numbered in the order the label file lists them, with
# its outline in the straightened box (0 to 1). Each label entry is called
# `entry`: `tibble()` builds its columns in order, so a column named `piece`
# would hide a variable of that name.
sample_box_pieces <- function(number) {
  label <- read_label_file(number)
  purrr::imap(label$pieces, \(entry, position) {
    tibble(
      box = number,
      piece = position,
      sku = entry$sku,
      tag = entry$tag %||% NA_character_,
      tag_read = isTRUE(entry$tagReadable) && !is.null(entry$tag),
      left = entry$rect$x,
      top = entry$rect$y,
      width = entry$rect$width,
      height = entry$rect$height
    )
  }) |>
    purrr::list_rbind()
}

# The box's corners on the photo, as fractions of the photo's width and
# height, measured from the top left.
sample_box_corners <- function(number) {
  quad <- read_label_file(number)$boxQuad
  ordered <- list(
    quad$topLeft, quad$topRight, quad$bottomRight, quad$bottomLeft
  )
  tibble(
    corner = c("top_left", "top_right", "bottom_right", "bottom_left"),
    x = purrr::map_dbl(ordered, "x"),
    y = purrr::map_dbl(ordered, "y")
  )
}

# What each sample box adds to a count, per product: "Box 1 added 15 pairs"
# reads from here, so the guide's words match the picture.
sample_box_counts <- function(number, shop) {
  sample_box_pieces(number) |>
    count(sku, name = "pieces") |>
    left_join(select(shop$products, sku, name, variant), by = "sku") |>
    arrange(desc(pieces), sku)
}

# The perspective transform from the straightened box (0 to 1 each way) to
# the photo: the four corners fix it. Solved once per box.
box_to_photo_transform <- function(corners) {
  square <- tibble(u = c(0, 1, 1, 0), v = c(0, 0, 1, 1))
  rows <- purrr::map(1:4, \(i) {
    u <- square$u[i]
    v <- square$v[i]
    x <- corners$x[i]
    y <- corners$y[i]
    rbind(
      c(u, v, 1, 0, 0, 0, -u * x, -v * x),
      c(0, 0, 0, u, v, 1, -u * y, -v * y)
    )
  })
  targets <- as.vector(rbind(corners$x, corners$y))
  solved <- solve(do.call(rbind, rows), targets)
  matrix(c(solved, 1), nrow = 3, byrow = TRUE)
}

apply_transform <- function(transform, u, v) {
  w <- transform[3, 1] * u + transform[3, 2] * v + transform[3, 3]
  tibble(
    x = (transform[1, 1] * u + transform[1, 2] * v + transform[1, 3]) / w,
    y = (transform[2, 1] * u + transform[2, 2] * v + transform[2, 3]) / w
  )
}

# Each piece's outline as four corners on the photo, ready for
# `geom_polygon()`.
pieces_on_photo <- function(number, pieces = sample_box_pieces(number)) {
  transform <- box_to_photo_transform(sample_box_corners(number))
  corners <- pieces |>
    tidyr::expand_grid(corner = 1:4) |>
    mutate(
      u = left + c(0, 1, 1, 0)[corner] * width,
      v = top + c(0, 0, 1, 1)[corner] * height
    )
  bind_cols(corners, apply_transform(transform, corners$u, corners$v))
}
