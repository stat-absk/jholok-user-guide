# App screenshots in a chapter: `screenshot("review.png")` shows the picture
# at phone size, with its description from scripts/screens.csv as the text a
# screen reader reads, and an optional caption under it.

screen_list <- function() {
  readr::read_csv(
    here::here("scripts", "screens.csv"),
    show_col_types = FALSE
  )
}

screenshot <- function(file, caption = NULL) {
  wanted <- file
  screen <- filter(screen_list(), file == wanted)
  if (nrow(screen) != 1) {
    stop("scripts/screens.csv has no ", wanted, call. = FALSE)
  }
  htmltools::tags$figure(
    class = "screenshot",
    htmltools::tags$img(
      src = image_path("app", wanted),
      alt = screen$alt,
      loading = "lazy"
    ),
    if (!is.null(caption)) htmltools::tags$figcaption(caption)
  )
}

# Pictures live in images/ at the top of the guide; chapters sit one folder
# down, in chapters/, so their links climb one level.
image_path <- function(...) {
  input <- knitr::current_input(dir = TRUE)
  in_chapters <- !is.null(input) && basename(dirname(input)) == "chapters"
  prefix <- if (in_chapters) ".." else "."
  file.path(prefix, "images", ...)
}
