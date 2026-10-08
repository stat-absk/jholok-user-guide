# Jholok user guide: tracker

The plan is in [PLAN.md](PLAN.md). Status: ☐ to do · ◐ in progress · ☑ done · ⏸ waiting on you.

Last updated 8 Oct 2026. Phases 0, 1 and 2 done; phase 3 drafted, waiting for your review.

## Waiting on you

| ID | Question | Status |
|---|---|---|
| Q1 | Where the guide ships (website, zip, PDF, a link in the app) | ⏸ |
| Q2 | Multi-page book or one long page | ⏸ (default: book) |
| Q3 | English only, or Bengali and Hindi later | ⏸ (default: English) |
| Q4 | Quarto: use the copy bundled with RStudio | ☑ (1.9.38) |
| Q5 | One guide for everyone, or a short separate one for counters | ⏸ (default: one, with markers) |

## Phase 0: set up

| ID | Task | Status |
|---|---|---|
| 0.1 | Scope, plan and tracker | ☑ |
| 0.2 | Quarto: RStudio's bundled 1.9.38 at `/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto`; `quarto check` passes with R 4.6.1, knitr 1.51 | ☑ |
| 0.3 | Install `lintr`, `styler` and `svglite` | ☑ |
| 0.4 | `jholok-user-guide.Rproj`, `renv` (implicit snapshot, `_dependencies.R` for tools), `.lintr` (tidyverse, 80 columns) | ☑ |
| 0.5 | `_quarto.yml`: book in 5 parts and 3 appendices, search, code hidden by default, `freeze: auto`, SVG charts | ☑ |
| 0.6 | `styles/`: Velvet & Gold colours from the app's colour sets, serif headings, light and dark (follows the reader's setting), audience pill, "What you'll learn" and "Remember" boxes; `R/guide_colours.R` | ☑ |
| 0.7 | An empty book that renders: welcome page, 16 chapter and 3 appendix placeholders, `_common.R`, README with build steps. Renders with no warnings, lintr clean, checked in light, dark and at phone width | ☑ |

## Phase 1: simulated shop (R)

| ID | Task | Status |
|---|---|---|
| 1.1 | `shop_catalogue()`, `shop_types()`: the demo shop's 7 types and 43 products, from `DemoCatalogue.swift` | ☑ |
| 1.2 | `simulate_shop()`: a line-for-line port of the app's demo generator. SplitMix64 in R with exact 64-bit arithmetic (16-bit limbs), seasons, the weekly top-up, the story, the rescue loop and the three counts, plus the count adjustments the app records | ☑ |
| 1.3 | `stock_on_hand()`, `stock_history()`: the sum of movements on any date | ☑ |
| 1.4 | `simulate_count()`: expected (ledger), on the shelf (with shelf changes such as a theft), counted (with mistakes), odd single earrings flagged; counted never reads expected | ☑ |
| 1.5 | `reconcile_count()`, `summarise_count()`: matched, short and over in units and at cost, per unit | ☑ |
| 1.6 | `stock_by_type()`, `daily_stock_value()`, `product_statuses()`: below-zero stock counts as none, products with no cost are counted apart | ☑ |
| 1.7 | `theme_guide()`, `scale_y_rupees()`, `table_guide()`; `shop_words.R` writes rupees (Indian grouping, lakh and crore), units and shares as the app does | ☑ |
| 1.8 | testthat: 50 checks, covering every rule in PLAN.md plus the showcase states and the app's money and share wording | ☑ |
| 1.9 | Matches the app exactly: all 713 movements, 43 products and 59 count lines are identical to the app's output (`scripts/app-demo-dump`) | ☑ |
| 1.10 | `lintr` clean; `styler` changes nothing | ☑ |
| 1.11 | Later, for chapters 9 to 11: the `-demo-boxes` story (the open count "Strongroom", the demo tag list and the sample boxes' tags, `DemoBoxes.swift`, `DemoTags.swift`) | ☐ |
| 1.12 | Later, for chapter 12: the `-off-shelf` story (stock sent to jangad and the karigar inside the open count, `DemoStockStates.swift`) | ☐ |

## Phase 2: screenshots and box pictures

| ID | Task | Status |
|---|---|---|
| 2.1 | `capture_screens.R`: launches each screen from its debug argument on the in-memory demo, light mode, status bar at 9:41, saves 640 px PNGs; stops if the guide's shop date (`screens_taken_on`) is not in the same week as today | ☑ |
| 2.2 | `scripts/screens.csv`: file, chapter, launch arguments, wait and the alt text a screen reader reads; `screenshot()` places one in a chapter | ☑ |
| 2.3 | First set: 28 screens, every one a launch argument can open (Overview and its three details, catalogue, product pages, ledger, counts, counting, who's counting, Review, Review with stock off the shelf, Result, Settings and four of its screens). Checked one by one; they match the R shop (₹2.73 Cr, 30 pairs · 20 sets · 120 pieces) | ☑ |
| 2.4 | Box screens from the sample boxes: the Strongroom count, the capture, the three box reviews, two tag scans, the piece sheet, Add piece, the count after adding a box, and the To identify queue | ☑ |
| 2.5 | Diagrams in R (`guide_diagrams.R`): one product's ledger as a running total (from the R shop), a count's life, the places stock can be. "Who may do what" will be a table in chapters 4 and 13 | ☑ |
| 2.6 | `scripts/copy_sample_boxes.R` copies the photos at 1,200 px with their label files to `images/boxes/`; `jpeg` added to renv | ☑ |
| 2.7 | `sample_boxes.R`: boxes, pieces, corners and a perspective transform from the straightened box to the photo | ☑ |
| 2.8 | `plot_box_photo()`: outlines and numbered tabs in the app's marker style, a selected piece in gold, a left-out one dashed, and a tray grid fitted to the slots. "Make it 2" is drawn as a diagram (2.9), since no sample piece is one | ☑ |
| 2.9 | `diagram_cards_not_pieces()`: one card is one pair, Make it 2 is the person's call, touching cards are warned and never split | ☑ |
| 2.10 | `sample_box_counts()` reads what each box adds from its label file; tests check every piece is a shop product | ☑ |
| 2.11 | `box_caption()` adds "a drawn example … not a photo of a real shop's box" to every box picture; tested | ☑ |
| 2.12 | Screens reached by a tap: 27 more, taken by the app's UI test `GuideScreenshotsUITests` (skipped unless `GUIDE_SCREENSHOTS_DIR` is set), which `capture_screens.R` runs for rows marked `ui test:`. Covers the lower parts of Overview, Review and Result, the product sheets, New count, Find by code, entering a count, Undo, Submit, Waiting for approval, Recount first and the blind recount, the approver's PIN, Complete, Export, the book stock plan, and People's Add person and log. 55 screens in all | ☑ |

## Phases 3 to 7: chapters

| ID | Chapter | For | Sources | Status |
|---|---|---|---|---|
| C0 | Welcome and how to use this guide: where to start for each role, the pictures | everyone | README | ☑ draft |
| C1 | Stock basics: products and SKUs, types and units, cost, list price and value | everyone | CLAUDE.md (Counting rules), visual-layer | ☑ draft |
| C2 | The ledger: movements, why stock is never typed, below zero | everyone | CLAUDE.md (Non-negotiables), DECISIONS | ☑ draft |
| C3 | Counting and checking against the books: short and over, blind counts, recount first, separation of duties | everyone | honest-summaries, people-and-log, CLAUDE.md (Counting rules) | ☑ draft |
| — | **Review point: tone and depth** | you | | ⏸ waiting for you |
| C4 | Setting up the shop | owner | people-and-log, Settings | ☐ |
| C5 | The catalogue | owner | Catalogue, tag list import | ☐ |
| C6 | Recording movements | owner, approvers | stock-states | ☐ |
| C7 | Reading the Overview | owner | visual-layer, honest-summaries | ☐ |
| C8 | A count from start to finish | counters | CLAUDE.md (Counting rules) | ☐ |
| C9 | Counting boxes: tags and photos | counters | photo-counting, box-review | ☐ |
| C10 | Pieces to identify later | counters | box-review | ☐ |
| C11 | Book stock | owner, approvers | book-stock | ☐ |
| C12 | Stock off the shelf and the cut-off | owner, approvers | stock-states | ☐ |
| C13 | Submit, review and complete | approvers | people-and-log, honest-summaries | ☐ |
| C14 | Results and the count report | owner, approvers | count-report | ☐ |
| C15 | Keeping data safe | owner | CLAUDE.md (Data: backups, privacy) | ☐ |
| C16 | Stories from the shop | everyone | all | ☐ |
| A | Glossary: 50 terms, each linked to its chapter; chapters 1 to 3 link each term's first use | everyone | all | ☑ draft |
| B | Questions and answers, troubleshooting | everyone | all | ☐ |
| C | What changed | everyone | git log | ☐ |

## Phase 8: check and ship

| ID | Task | Status |
|---|---|---|
| 8.1 | Every rule stated checked against CLAUDE.md and docs/design | ☐ |
| 8.2 | Plain-language pass: short sentences, each term explained first time | ☐ |
| 8.3 | Photo counting described as unmeasured on real boxes; X1 values marked "coming" | ☐ |
| 8.4 | Links, image alt text, light and dark check, phone width | ☐ |
| 8.5 | `lintr` and testthat clean, `renv::status()` clean | ☐ |
| 8.6 | Render the book and the single-file HTML | ☐ |
| 8.7 | **Review point: release 1** | ⏸ |

## Phase 9: keep it current

| ID | Task | Status |
|---|---|---|
| 9.1 | `check_sources.R`: chapters whose sources changed since the last guide release, and changes to `Jholok/DevTools/DemoBoxes/` | ☐ |
| 9.2 | A line in the project CLAUDE.md: a feature change updates its chapter and screenshots | ☐ |
| 9.3 | A "What changed" entry for each release | ☐ |

## Log

| Date | What happened |
|---|---|
| 7 Oct 2026 | Scope, plan and tracker written. `lintr` and `styler` are missing. R 4.6.1 has tidyverse, gt, knitr, rmarkdown, renv, here, glue, scales and testthat. |
| 7 Oct 2026 | Quarto found inside RStudio (1.9.38); `quarto check` passes for R and knitr. Q4 closed. |
| 7 Oct 2026 | Phase 0 done. The book renders with RStudio's Quarto; the preview runs as `user-guide` in `.claude/launch.json`. |
| 7 Oct 2026 | Box pictures added to the plan (D9, phase 2): the app's three sample boxes for screenshots, R figures drawn over them, plain R diagrams; no new photo-like images. |
| 7 Oct 2026 | Phase 1 done. The R shop reproduces the app's demo exactly (713 movements, 59 count lines). Simulating takes about 11 seconds, so `load_shop()` caches it. The demo's stock at the end is ₹2.73 Cr at cost. |
| 7 Oct 2026 | The guide became its own private repository, stat-absk/jholok-user-guide, still in `Jholok/user-guide/`; the app repository ignores the folder. |
| 8 Oct 2026 | Phase 2 except 2.12: 28 screenshots, box pictures drawn from the sample boxes' label files, and three idea diagrams. `screens_taken_on` (8 Oct 2026) moves the R shop to the screenshots' dates (the app moves its demo by 14 days today). Figures sit on a raised card so they read in dark mode. 66 tests pass. |
| 8 Oct 2026 | 2.12 done with a screenshot UI test in the app repo; 55 screenshots. The demo's book file asks no status-word question (its words are all known), so that question has no screenshot. |
| 8 Oct 2026 | Phase 3 drafted: the welcome page, chapters 1 to 3 and the glossary. Every figure in the text is computed from the R shop and matches the screenshots. `date_words()` and `movement_name()` added; 68 tests pass. |
