# Lists what in the guide may be out of date: the chapters whose app sources
# changed since the guide was last checked against the app, the screenshots in
# those chapters, and the R shop, sample boxes or screenshot tools when what
# they copy changed.
#
# scripts/sources.csv says what each chapter relies on (paths in the app's
# folder, `*` for any part). scripts/releases.csv records, for each release of
# the guide, the app commit it was checked against; the last row is the one
# compared with. Uncommitted changes in the app count too.
#
# Run it from the guide's folder:
#   Rscript scripts/check_sources.R            # since the last release
#   Rscript scripts/check_sources.R ef586c6    # since another app commit
#
# After updating the guide for a new release, add a row to releases.csv with
# the app commit it now matches.

suppressPackageStartupMessages({
  library(dplyr)
  library(readr)
})

app_root <- normalizePath(here::here(".."))

# What each target needs doing when its sources change.
next_steps <- c(
  "the R shop" = paste(
    "Port the demo's change to R/, write the fixtures again with",
    "scripts/app-demo-dump, and run the tests."
  ),
  "the sample boxes" = paste(
    "Run scripts/copy_sample_boxes.R and check the box figures."
  ),
  "the screenshots" = "Retake them with scripts/capture_screens.R."
)

git <- function(...) {
  out <- system2("git", c("-C", shQuote(app_root), ...), stdout = TRUE)
  status <- attr(out, "status")
  if (!is.null(status) && status != 0) {
    stop("git ", paste(...), " failed", call. = FALSE)
  }
  out
}

read_sources <- function() {
  read_csv(here::here("scripts", "sources.csv"), show_col_types = FALSE)
}

last_checked_commit <- function() {
  releases <- read_csv(
    here::here("scripts", "releases.csv"),
    col_types = cols(.default = col_character())
  )
  releases$app_commit[[nrow(releases)]]
}

# Files changed since `commit`, committed or not.
changed_files <- function(commit) {
  committed <- git("diff", "--name-only", commit, "HEAD")
  uncommitted <- substring(git("status", "--porcelain"), 4)
  setdiff(unique(c(committed, uncommitted)), "")
}

# One row for each target and changed file it relies on.
stale_targets <- function(changed, sources = read_sources()) {
  sources |>
    mutate(pattern = utils::glob2rx(source)) |>
    reframe(
      file = changed[grepl(pattern, changed)],
      .by = c(target, source)
    ) |>
    distinct(target, file)
}

# Sources that match nothing in the app any more: a file was renamed or
# removed, so sources.csv needs updating.
missing_sources <- function(sources = read_sources(), files = git("ls-files")) {
  sources |>
    filter(!vapply(
      utils::glob2rx(source),
      \(pattern) any(grepl(pattern, files)),
      logical(1)
    ))
}

# Chapters that list no sources, so a change could never flag them.
unwatched_chapters <- function(sources = read_sources()) {
  chapters <- tools::file_path_sans_ext(
    basename(Sys.glob(here::here("chapters", "[0-9]*.qmd")))
  )
  setdiff(chapters, sources$target)
}

screens_of <- function(chapter) {
  number <- substr(chapter, 1, 2)
  screens <- read_csv(
    here::here("scripts", "screens.csv"),
    col_types = cols(.default = col_character())
  )
  screens$file[screens$chapter == number]
}

commits_touching <- function(commit, files) {
  if (length(files) == 0) {
    return(character())
  }
  git(
    "log", "--no-merges", "--format=%h\\ %s", paste0(commit, "..HEAD"),
    "--", files
  )
}

report <- function(commit) {
  changed <- changed_files(commit)
  stale <- stale_targets(changed)
  cat(
    "Since app commit ", commit, ": ", length(changed), " files changed, ",
    n_distinct(stale$target), " parts of the guide to check.\n",
    sep = ""
  )
  for (target in sort(unique(stale$target))) {
    files <- stale$file[stale$target == target]
    cat("\n", target, "\n", sep = "")
    cat(paste0("  changed: ", files, "\n"), sep = "")
    commits <- commits_touching(commit, files)
    if (length(commits) > 0) {
      cat(paste0("  commit:  ", commits, "\n"), sep = "")
    }
    if (target %in% names(next_steps)) {
      cat("  then:    ", next_steps[[target]], "\n", sep = "")
    } else {
      screens <- screens_of(target)
      if (length(screens) > 0) {
        cat("  screens: ", paste(screens, collapse = ", "), "\n", sep = "")
      }
    }
  }
  if (nrow(stale) > 0) {
    cat(
      "\nCheck the glossary, the questions and answers and the stories for",
      "anything these change, and add a \"What changed\" entry.\n"
    )
  }

  missing <- missing_sources()
  if (nrow(missing) > 0) {
    cat("\nNo longer in the app; update scripts/sources.csv:\n")
    cat(paste0("  ", missing$target, ": ", missing$source, "\n"), sep = "")
  }
  unwatched <- unwatched_chapters()
  if (length(unwatched) > 0) {
    cat("\nChapters with no sources in scripts/sources.csv:\n")
    cat(paste0("  ", unwatched, "\n"), sep = "")
  }
  invisible(stale)
}

if (sys.nframe() == 0) {
  commit <- commandArgs(trailingOnly = TRUE)
  report(if (length(commit) > 0) commit[[1]] else last_checked_commit())
}
