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

## Publish the book

The book is hosted on the owner's GitHub Pages site, at
<https://stat-absk.github.io/jholok-guide/>. After rendering:

```bash
Rscript scripts/publish_book.R
```

It copies `_book/` into the site's folder (`~/Github_Page`, the
stat-absk.github.io repository): into `jholok-guide/`, which the site's
`_quarto.yml` lists under `resources`, and into `docs/jholok-guide/`, which
Pages serves. Then commit and push the site. The site's link check also
checks the guide's pages.

## The single-file guide

For shops with poor internet, one HTML file holds the whole guide, every
picture and style inside it:

```bash
Rscript scripts/build_single_file.R
```

It writes `_release/jholok-user-guide-<version>.html` (not committed), about
19 MB. It uses macOS's `sips` to make the screenshots JPEG.

## Keep it current

When the app changes, list what in the guide may be out of date:

```bash
Rscript scripts/check_sources.R
```

It compares the app with the commit the guide was last checked against (the
last row of `scripts/releases.csv`) and lists, for each chapter whose sources
changed, the changed files, their commits and the chapter's screenshots. It
also flags the R shop (the app's demo changed), the sample boxes and the
screenshot tools. `scripts/sources.csv` says which app files each chapter
relies on; add a row when a chapter comes to rely on a new one (a test checks
that every chapter has sources and that every source still exists).

To release the guide:

1. Update the chapters the check lists, retake their screenshots, and render.
2. Add an entry to `chapters/what-changed.qmd` and raise `version` in
   `_quarto.yml`.
3. Add a row to `scripts/releases.csv` with the guide and app versions, the
   date and the app commit the guide now matches.
4. Publish the book (`scripts/publish_book.R`), build the single file, and
   send the file with the link.

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
