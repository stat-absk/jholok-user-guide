# Jholok user guide

The guide for people using Jholok for the first time. It is written in R and
Quarto, and is shipped separately from the app. The plan is in
[PLAN.md](PLAN.md) and the progress in [TRACKER.md](TRACKER.md).

## Build it

Open `jholok-user-guide.Rproj` in RStudio. `renv` restores the pinned packages
on first open (`renv::restore()` if it asks). Then Build → Render Book, or from
a terminal in this folder:

```bash
/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto render
```

The book is written to `_book/` (not committed). Open `_book/index.html`
through a local server so its styles load, for example
`python3 -m http.server 4321 --directory _book`.

Chapters keep their results in `_freeze/` and only run again when the
chapter itself changes. After changing anything in `R/`, delete `_freeze/`
before rendering, so every chapter picks the change up.

## Check the code

```r
lintr::lint_dir(".")
styler::style_dir(
  ".",
  exclude_dirs = c("renv", "_book", "_freeze", "_cache", "scripts")
)
testthat::test_dir("tests/testthat")
```

All R code follows the tidyverse style guide: the native pipe `|>`,
snake_case, lines under 80 characters, and comments that say why.

## Where things are

- `index.qmd` and `chapters/`: the guide, one file per chapter.
- `_common.R`: run at the top of every chapter, so every chapter uses the same
  shop and helpers.
- `R/`: the simulated shop and the chart and table helpers.
  - `splitmix64.R`, `shop_catalogue.R`, `shop_calendar.R`, `simulate_product.R`,
    `shop_story.R` and `simulate_shop.R` rebuild the app's demo shop exactly:
    the same generator, seed, catalogue, seasons and story.
  - `shop_counts.R` counts it (blind, with shelf changes and counting
    mistakes) and reconciles; `shop_values.R` gives stock by type, value and
    each product's state; `shop_words.R` writes figures as the app does.
  - `load_shop()` keeps a copy in `_cache/` (not committed), since simulating
    takes about 10 seconds.
- `tests/testthat/`: the shop keeps the app's rules, and matches the app's
  demo (`fixtures/`, written by `scripts/app-demo-dump`, a small Swift tool
  run only when the app's demo changes).
- `styles/`: the app's Velvet & Gold colours, light and dark.
- `images/app/`: screenshots, taken by `scripts/capture_screens.R` from the
  list in `scripts/screens.csv`. Rows with launch arguments open their screen
  directly; rows marked `ui test:` are taken by the app's UI test
  `JholokUITests/GuideScreenshotsUITests`, which taps its way there (it
  builds the app, so that part takes several minutes). Before retaking them, set `screens_taken_on`
  in `R/guide_settings.R` to that day: the app moves its demo story to end
  near today, and the guide's shop must end on the same day.
- `images/boxes/`: the app's three sample box photos, made smaller, with their
  label files (`scripts/copy_sample_boxes.R`). `R/box_figures.R` draws the
  app's markers on them; `R/guide_diagrams.R` draws the plain diagrams.
- `_dependencies.R`: packages renv must record that no chapter loads by name.
- `_freeze/`: saved results of each chapter's R code, committed so the
  numbers stay the same until a chapter changes.
