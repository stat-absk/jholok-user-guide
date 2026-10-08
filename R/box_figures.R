# Pictures of the sample boxes with the app's markers drawn on them, and the
# caption every box picture carries.
#
# The markers copy the box review's (Jholok/Features/BoxCount/
# PieceMarkersOverlay.swift): a white outline with a soft dark edge, gold for
# the piece being looked at, dashed for one left out, and a numbered tab.

# Every box picture says what it is: a drawing, not a real shop's box.
drawn_box <- paste(
  "The box is a drawn example the app uses for practice, not a photo of a",
  "real shop's box."
)

box_caption <- function(text) {
  paste(text, drawn_box)
}

read_box_photo <- function(number) {
  jpeg::readJPEG(sample_box_path(number, "jpg"))
}

# The sample box's photo with its pieces outlined.
#
# - `numbers`: draw each piece's numbered tab.
# - `selected`: piece numbers to draw in gold, as the piece being looked at.
# - `extra`: outlines that aren't in the label file, in the straightened box
#   (columns `left`, `top`, `width`, `height` and `removed`), such as an empty
#   card the app might have mistaken for a piece.
# - `grid`: `c(rows, columns)` to draw a tray grid over the box.
plot_box_photo <- function(number, numbers = TRUE, selected = integer(),
                           extra = NULL, grid = NULL) {
  photo <- read_box_photo(number)
  aspect <- ncol(photo) / nrow(photo)
  to_plot <- \(points) mutate(points, x = x * aspect, y = -y)

  pieces <- sample_box_pieces(number) |>
    mutate(removed = FALSE)
  if (!is.null(extra)) {
    extra_pieces <- extra |>
      mutate(box = number, piece = max(pieces$piece) + row_number())
    pieces <- bind_rows(pieces, extra_pieces)
  }
  outlines <- pieces_on_photo(number, pieces) |>
    to_plot() |>
    mutate(is_selected = piece %in% selected)

  corners <- sample_box_corners(number) |>
    to_plot()
  margin <- 0.03
  plot <- ggplot() +
    annotation_raster(photo, xmin = 0, xmax = aspect, ymin = -1, ymax = 0) +
    marker_outlines(outlines)

  if (!is.null(grid)) {
    plot <- plot + tray_grid(number, grid, aspect, pieces)
  }
  if (numbers) {
    plot <- plot + marker_tabs(outlines)
  }
  plot +
    coord_fixed(
      xlim = range(corners$x) + c(-margin, margin),
      ylim = range(corners$y) + c(-margin, margin),
      expand = FALSE
    ) +
    theme_void()
}

marker_outlines <- function(outlines) {
  plain <- filter(outlines, !is_selected)
  chosen <- filter(outlines, is_selected)
  list(
    # The soft dark edge keeps a white outline visible on a pale card.
    geom_polygon(
      aes(x, y, group = piece),
      data = outlines,
      fill = NA,
      colour = scales::alpha("black", 0.25),
      linewidth = 1.6
    ),
    geom_polygon(
      aes(x, y, group = piece, linetype = removed),
      data = plain,
      fill = NA,
      colour = "white",
      linewidth = 0.8
    ),
    geom_polygon(
      aes(x, y, group = piece, linetype = removed),
      data = chosen,
      fill = NA,
      colour = guide_colours$gold_mid,
      linewidth = 1.4
    ),
    scale_linetype_manual(
      values = c(`FALSE` = "solid", `TRUE` = "22"),
      guide = "none"
    )
  )
}

# A small numbered tab at each piece's top left corner.
marker_tabs <- function(outlines) {
  tabs <- outlines |>
    filter(corner == 1, !removed)
  geom_label(
    aes(x, y, label = piece),
    data = tabs,
    fill = guide_colours$surface_raised,
    colour = guide_colours$text_primary,
    size = 2.6,
    fontface = "bold",
    linewidth = 0,
    label.r = grid::unit(0.2, "lines"),
    label.padding = grid::unit(0.12, "lines")
  )
}

# The grid covers the pieces, not the box's frame, with half a gap around
# them, as a tray's slots do. Straight lines in the box stay straight on the
# photo, so each grid line only needs its two ends transformed.
tray_grid <- function(number, grid, aspect, pieces) {
  transform <- box_to_photo_transform(sample_box_corners(number))
  rows <- grid[1]
  columns <- grid[2]
  span <- \(starts, ends, slots) {
    gap <- (max(ends) - min(starts) - slots * mean(ends - starts)) /
      (slots - 1)
    seq(min(starts) - gap / 2, max(ends) + gap / 2, length.out = slots + 1)
  }
  u_lines <- span(pieces$left, pieces$left + pieces$width, columns)
  v_lines <- span(pieces$top, pieces$top + pieces$height, rows)
  across <- tibble(
    u_start = min(u_lines), u_end = max(u_lines),
    v_start = v_lines, v_end = v_lines
  )
  down <- tibble(
    u_start = u_lines, u_end = u_lines,
    v_start = min(v_lines), v_end = max(v_lines)
  )
  lines <- bind_rows(across, down)
  starts <- apply_transform(transform, lines$u_start, lines$v_start)
  ends <- apply_transform(transform, lines$u_end, lines$v_end)
  segments <- tibble(
    x = starts$x * aspect, y = -starts$y,
    xend = ends$x * aspect, yend = -ends$y
  )
  list(
    geom_segment(
      aes(x, y, xend = xend, yend = yend),
      data = segments,
      colour = scales::alpha("black", 0.45),
      linewidth = 1.2
    ),
    geom_segment(
      aes(x, y, xend = xend, yend = yend),
      data = segments,
      colour = "white",
      linewidth = 0.6
    )
  )
}
