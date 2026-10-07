# The guide's look for charts and tables: the app's colours, quiet axes and
# no decoration that doesn't carry data.

theme_guide <- function(base_size = 13) {
  theme_minimal(base_size = base_size, base_family = "") +
    theme(
      plot.background = element_rect(fill = "transparent", colour = NA),
      panel.background = element_rect(fill = "transparent", colour = NA),
      panel.grid.minor = element_blank(),
      panel.grid.major.x = element_blank(),
      panel.grid.major.y = element_line(
        colour = guide_colours$hairline,
        linewidth = 0.3
      ),
      axis.text = element_text(colour = guide_colours$text_secondary),
      axis.title = element_text(colour = guide_colours$text_secondary),
      plot.title = element_text(
        face = "bold",
        colour = guide_colours$text_primary
      ),
      plot.subtitle = element_text(colour = guide_colours$text_secondary),
      plot.caption = element_text(
        colour = guide_colours$text_secondary,
        hjust = 0
      ),
      legend.position = "top",
      legend.justification = "left",
      legend.title = element_blank()
    )
}

scale_y_rupees <- function(...) {
  scale_y_continuous(labels = rupees_short, ...)
}

# A table in the guide's style. Numbers line up, and the header is quiet.
table_guide <- function(data) {
  data |>
    gt::gt() |>
    gt::tab_options(
      table.background.color = "transparent",
      table.font.size = gt::px(15),
      column_labels.font.weight = "600",
      column_labels.border.top.color = guide_colours$hairline,
      column_labels.border.bottom.color = guide_colours$hairline,
      table_body.border.bottom.color = guide_colours$hairline,
      table_body.hlines.color = guide_colours$hairline,
      table.border.top.style = "hidden",
      table.border.bottom.style = "hidden",
      data_row.padding = gt::px(6)
    ) |>
    gt::opt_table_font(font = "inherit") |>
    gt::cols_align(align = "right", columns = where(is.numeric))
}
