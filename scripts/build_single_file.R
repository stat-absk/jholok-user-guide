# Builds the guide as one self-contained HTML file, for shops with poor
# internet: every picture and style is inside the file, so it opens offline
# and can be sent like any other file.
#
# Run from the guide's folder, after the book renders:
#   Rscript scripts/build_single_file.R
# It writes _release/jholok-user-guide-<version>.html. The chapters are
# joined in the book's order into _single/guide.qmd, with links between
# pages turned into links within the page. Screenshots go in as JPEG (made
# with macOS's sips), which keeps the file about a third of the size.

quarto <- file.path(
  "/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto"
)
book <- yaml::read_yaml(here::here("_quarto.yml"))$book
version <- sub("^Guide ([0-9.]+).*$", "\\1", book$version)
build_dir <- here::here("_single")

# The book's files in order, with a heading for each part.
book_files <- function(book) {
  parts <- lapply(book$chapters, \(entry) {
    if (is.character(entry)) {
      return(list(heading = NULL, files = entry))
    }
    list(heading = entry$part, files = unlist(entry$chapters))
  })
  appendices <- list(heading = "Appendices", files = unlist(book$appendices))
  c(parts, list(appendices))
}

# Links to other pages of the book become links within the one page.
link_within <- function(lines) {
  replacements <- c(
    "\\((chapters/)?glossary\\.qmd#" = "(#",
    "\\((chapters/)?glossary\\.qmd\\)" = "(#sec-glossary)",
    "\\((chapters/)?questions\\.qmd\\)" = "(#sec-questions)",
    "\\((chapters/)?what-changed\\.qmd\\)" = "(#sec-what-changed)"
  )
  for (pattern in names(replacements)) {
    lines <- gsub(pattern, replacements[[pattern]], lines)
  }
  left <- grep("\\]\\([^)]*\\.qmd", lines, value = TRUE)
  if (length(left) > 0) {
    stop("A link to a page isn't handled: ", left[[1]], call. = FALSE)
  }
  lines
}

# Appendices keep their letters out of the chapter numbers.
unnumbered <- function(lines) {
  first <- grep("^# ", lines)[[1]]
  heading <- lines[[first]]
  if (!grepl("unnumbered", heading, fixed = TRUE)) {
    lines[[first]] <- if (grepl("\\}\\s*$", heading)) {
      sub("\\}\\s*$", " .unnumbered}", heading)
    } else {
      paste(heading, "{.unnumbered}")
    }
  }
  lines
}

part_heading <- function(heading) {
  if (is.null(heading)) {
    return(character())
  }
  c(paste0("# ", heading, " {.unnumbered .part}"), "")
}

front_matter <- function(book, version) {
  c(
    "---",
    paste0('title: "', book$title, '"'),
    paste0('subtitle: "', book$subtitle, " · ", book$version, '"'),
    "date: last-modified",
    'date-format: "D MMMM YYYY"',
    "lang: en-GB",
    "format:",
    "  html:",
    "    embed-resources: true",
    "    theme:",
    "      light: [cosmo, ../styles/light.scss, ../styles/rules.scss]",
    "      dark: [cosmo, ../styles/dark.scss, ../styles/rules.scss]",
    "    respect-user-color-scheme: true",
    "    toc: true",
    "    toc-location: left",
    "    toc-depth: 1",
    '    toc-title: "Contents"',
    "    number-sections: true",
    "    number-depth: 2",
    "    fig-align: center",
    "    fig-responsive: true",
    "    link-external-newwindow: true",
    "execute:",
    "  echo: false",
    "  warning: false",
    "  message: false",
    "knitr:",
    "  opts_chunk:",
    "    fig.width: 7",
    "    fig.height: 4",
    "    dev: svglite",
    "    dev.args:",
    '      bg: "#FFFDF8"',
    "---",
    "",
    "```{r}",
    "#| include: false",
    "# The folder's own _quarto.yml would make here() start in _single.",
    'here::i_am("_single/guide.qmd")',
    'options(guide.image_root = "images")',
    "```",
    ""
  )
}

copy_pictures <- function(build_dir) {
  app_dir <- file.path(build_dir, "images", "app")
  report_dir <- file.path(build_dir, "images", "report")
  dir.create(app_dir, recursive = TRUE, showWarnings = FALSE)
  dir.create(report_dir, recursive = TRUE, showWarnings = FALSE)
  screens <- list.files(here::here("images", "app"), "\\.png$")
  for (screen in screens) {
    status <- system2(
      "sips",
      c(
        "-s", "format", "jpeg", "-s", "formatOptions", "82",
        shQuote(here::here("images", "app", screen)),
        "--out", shQuote(file.path(app_dir, sub("\\.png$", ".jpg", screen)))
      ),
      stdout = FALSE
    )
    if (status != 0) {
      stop("sips couldn't convert ", screen, call. = FALSE)
    }
  }
  file.copy(
    list.files(here::here("images", "report"), full.names = TRUE),
    report_dir,
    overwrite = TRUE
  )
  invisible(length(screens))
}

build_single_file <- function() {
  unlink(build_dir, recursive = TRUE)
  dir.create(build_dir)
  # Its own project, so Quarto doesn't treat the file as part of the book.
  writeLines("project:\n  type: default", file.path(build_dir, "_quarto.yml"))
  copy_pictures(build_dir)

  body <- unlist(lapply(book_files(book), \(part) {
    in_appendix <- identical(part$heading, "Appendices")
    c(
      part_heading(part$heading),
      unlist(lapply(part$files, \(file) {
        lines <- link_within(readLines(here::here(file)))
        if (in_appendix) {
          lines <- unnumbered(lines)
        }
        c(lines, "")
      }))
    )
  }))
  writeLines(
    c(front_matter(book, version), body),
    file.path(build_dir, "guide.qmd")
  )

  guide <- shQuote(file.path(build_dir, "guide.qmd"))
  status <- system2(quarto, c("render", guide))
  if (status != 0) {
    stop("Quarto couldn't render the single file.", call. = FALSE)
  }
  release <- here::here("_release")
  dir.create(release, showWarnings = FALSE)
  out <- file.path(release, paste0("jholok-user-guide-", version, ".html"))
  file.copy(file.path(build_dir, "guide.html"), out, overwrite = TRUE)
  message(
    "Wrote ", out, " (", round(file.size(out) / 1e6, 1), " MB)"
  )
  invisible(out)
}

build_single_file()
