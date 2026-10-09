# Puts the rendered book on the owner's GitHub Pages site,
# https://stat-absk.github.io/jholok-guide/.
#
# The site (stat-absk/stat-absk.github.io) is a Quarto website that GitHub
# Pages serves from its docs/ folder. The book goes into two places there:
# - jholok-guide/, listed under `resources` in the site's _quarto.yml, so the
#   site's own renders copy it into docs/ as it is;
# - docs/jholok-guide/, so it is live without rendering the whole site.
# The site's .gitignore leaves out `*_files/` folders, which hold the book's
# figures, so it keeps an exception for jholok-guide.
#
# Render the book first, then run it from the guide's folder:
#   Rscript scripts/publish_book.R [path to the site, default ~/Github_Page]
# and commit and push the site.

site_folder <- "jholok-guide"

publish_book <- function(site = "~/Github_Page") {
  site <- normalizePath(site, mustWork = TRUE)
  book <- here::here("_book")
  if (!file.exists(file.path(book, "index.html"))) {
    stop("Render the book first: _book/index.html is missing.", call. = FALSE)
  }
  config <- readLines(file.path(site, "_quarto.yml"))
  if (!any(grepl(paste0("- ", site_folder, "/"), config, fixed = TRUE))) {
    stop(
      "The site's _quarto.yml doesn't list ", site_folder,
      "/ under resources, so its next render would drop the guide.",
      call. = FALSE
    )
  }
  targets <- file.path(site, c(site_folder, file.path("docs", site_folder)))
  for (target in targets) {
    unlink(target, recursive = TRUE)
    dir.create(target, recursive = TRUE)
    file.copy(
      list.files(book, full.names = TRUE, all.files = FALSE),
      target,
      recursive = TRUE
    )
  }
  files <- length(list.files(file.path(site, site_folder), recursive = TRUE))
  message(
    "Copied ", files, " files into ", site_folder, "/ and docs/",
    site_folder, "/ of ", site, ". Commit and push the site."
  )
  invisible(site)
}

if (sys.nframe() == 0) {
  site <- commandArgs(trailingOnly = TRUE)
  publish_book(if (length(site) > 0) site[[1]] else "~/Github_Page")
}
