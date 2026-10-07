# Jholok user guide: scope and action plan

Started 7 Oct 2026. The tracker is [TRACKER.md](TRACKER.md).

## What was asked

A tutorial for people using Jholok for the first time. It should:

- explain every part of the app: how to use it, why it works the way it does, and how it works underneath;
- introduce the shop and accounting ideas the app depends on, gently and in plain language;
- be an HTML page with use cases, demos and worked examples;
- show the features using simulated inventory data;
- be written entirely in R and Quarto, as an R project, with every piece of R code in tidyverse style (`tidy-code-style`);
- keep growing with the app and ship to users separately from it.

## How big this is

It is a large piece of work. It is roughly a short book, not one page.

| Measure | Estimate |
|---|---|
| Things the guide has to explain | 7 areas of the app (Overview, Catalogue, Count, Box counting, Ledger, People, Settings), about 60 screens, and 9 council features with their own rules (book stock, stock states, people and the log, the report, identify later, and others) |
| Background ideas to teach first | about 25 terms: SKU, unit, stock on hand, movement, ledger, cost and price, stock value, shrinkage, physical count, blind count, reconciliation, short and over, cut-off, books, jangad, karigar, approver, separation of duties, audit trail, and more |
| Chapters | 16, plus a glossary, questions and answers, and a "what changed" page |
| Words | 25,000 to 35,000 |
| Pictures | 80 to 120 app screenshots, 15 to 25 charts and tables made in R, 6 to 10 drawn diagrams, and 6 to 10 box figures drawn over the sample box photos |
| R code | a small simulation library (about 10 functions) with tests, and one chunk or more in most chapters |
| Sessions | about 8 to 12 working sessions, set out in phases below |

### What makes it hard

1. **The guide has to be correct.** The app has strict rules: counting is blind, nothing changes stock until a count is completed, there are no percentages on fewer than 10, and pairs are never added to sets. A tutorial that rounds these off would teach people the wrong thing. Every rule the guide states will be checked against `CLAUDE.md` and `docs/design/`.
2. **Two kinds of example data.** The screenshots come from the app's own demo shop ("Jholok Jewellers", `JholokDemo`). The worked examples come from data simulated in R. If the two tell different stories (different products, people or numbers), readers get confused. The R simulation will copy the demo shop's catalogue, types, people (the owner Bidisha, and Sita, Ramesh and Meena) and counts, so screenshots and examples describe the same shop.
3. **The guide has to keep up with the app.** Each chapter records the app features and design documents it relies on. A check script lists the chapters whose sources changed since the last release of the guide.
4. **Honest about what isn't proven.** Photo counting has not been measured on real boxes. The guide must say so where it describes it, as the TestFlight note does. Rupee values in the count report wait for X1.
5. **Plain language.** The readers are shop owners and staff, not accountants or developers. Use short sentences and the app's own words, explain each term the first time it appears, and link it to the glossary.

### What is out of scope

- Teaching R. The R code builds the guide; readers never need to read or run it, and code is hidden in the output by default.
- Translations. The guide is planned in English only for now (open question 3).
- Developer documentation. That stays in `docs/`.

## Decisions taken by default (change any of them)

| # | Decision | Why |
|---|---|---|
| D1 | The guide is its own private repository, [stat-absk/jholok-user-guide](https://github.com/stat-absk/jholok-user-guide), kept in the `user-guide/` folder inside the app's folder. The app repository ignores that folder. | It sits next to the code and design documents it describes, and relative paths to the app (`../JholokKit`, the sample boxes, the simulator) keep working, while the guide has its own history and can be shared on its own. |
| D2 | Format: a Quarto **book** rendered to HTML (multi-page, with search and a contents sidebar), plus one self-contained HTML file per release for offline sharing. | A guide of 16 chapters is too long for one scrolling page. Shop staff may also have poor internet, so the single file helps. |
| D3 | The R simulation is a set of functions in `user-guide/R/`, tested with `testthat`, and loaded by each chapter. It is a faithful port of the app's demo generator (`JholokDemo`): the same SplitMix64 generator and seed, catalogue, seasons and story, so it reproduces the app's demo exactly. A test compares it with the app's own output, written by a small Swift tool (`scripts/app-demo-dump`). | Every chapter uses the same shop and the same seed, so numbers agree across chapters and with the screenshots. |
| D4 | `renv` pins the R packages, and Quarto's `freeze` keeps rendered results. | Anyone can rebuild the guide and get the same numbers. |
| D5 | The R code uses the native pipe `|>` and snake_case, is checked by `lintr` and formatted by `styler` with the tidyverse style. | This is what `tidy-code-style` asks for. |
| D6 | Screenshots are taken from the simulator with the app's DEBUG demo launch arguments (`-demo`, `-demo-counting`, `-demo-boxes`, `-count review`, and so on). An R script drives `xcrun simctl` and saves them to `user-guide/images/app/`. | They can be retaken whenever the screens change, and they always show the demo shop, never real stock. |
| D7 | Each page is in light mode and set to the iPhone 17 Pro. | The pictures stay consistent from page to page. |
| D8 | Each release of the guide matches an app version ("Guide for Jholok 1.3"), with a "What changed" page. | Users know which app the guide describes. |
| D9 | Box pictures come from the app's three sample boxes (see "Box pictures" below). R draws over them and draws plain diagrams. It never makes new photo-like images, and `jholok-synth` is not run for more boxes without your say. | The sample boxes are already drawn from the demo shop's tags, so screenshots, figures and numbers all describe the same boxes. |

## Open questions for you

1. **Where it ships:** a website (GitHub Pages or similar), a zip of HTML files, a PDF too, or a link from inside the app?
2. **Format:** is the multi-page book (D2) right, or do you want one long HTML page?
3. **Languages:** English only, or Bengali and Hindi later? Translation is much easier to plan for now (short sentences, no text inside images).
4. **Tooling:** settled. Quarto 1.9.38 comes with RStudio (`/Applications/RStudio.app/Contents/Resources/app/quarto/bin/quarto`), and `quarto check` passes with R 4.6.1. Only `lintr` and `styler` still need installing in R.
5. **Readers:** owner, approvers and counters all read one guide, with "For counters" and "For the owner" markers on each chapter. Or do you want separate short guides for counters?

## The R project

```
user-guide/
  jholok-user-guide.Rproj
  _quarto.yml            book settings, chapters, theme
  renv.lock              pinned packages
  .lintr                 tidyverse style
  index.qmd              welcome
  chapters/              one .qmd per chapter
  R/
    shop_catalogue.R     the demo shop's types and products
    simulate_movements.R a year of sales, receipts and returns
    simulate_count.R     a count with the mistakes real counts have
    reconcile_count.R    expected vs counted, short and over
    stock_values.R       units and value, by type
    sample_boxes.R       reads the sample box photos and their label files
    box_figures.R        draws over a box photo, and plain box diagrams
    plot_helpers.R       the guide's chart style (app colours)
    table_helpers.R      gt tables in the guide's style
  tests/testthat/        the simulation keeps the app's rules
  scripts/
    capture_screens.R    simulator screenshots from launch arguments
    check_sources.R      chapters whose sources changed since the last release
  images/app/            screenshots
  images/diagrams/       drawn diagrams (SVG)
  images/boxes/          copies of the app's sample box photos, made smaller
  styles/                CSS: Velvet & Gold colours and serif headings
  PLAN.md, TRACKER.md
```

### What the simulation has to get right

The tests check each of these:

- Stock on hand is always the sum of movements, and no number is stored.
- Earrings are counted in pairs and sets count as 1. An odd earring is flagged, never rounded.
- A count changes stock only for the lines that were ticked when it was completed.
- Counted figures are made without looking at expected stock. The simulation draws real stock, then counting errors (missed pieces, double counts, a piece in the wrong box, an odd earring), and only then compares.
- A share of fewer than 10 is written "3 of 4", never as a percentage.
- Units are never added across pairs, sets and pieces.
- The same seed gives the same shop every time.

## Box pictures

The app has three sample box photos in `Jholok/DevTools/DemoBoxes/`
(`demo-box-1.jpg` to `demo-box-3.jpg`). They are not real photos: the app's
Swift tool `jholok-synth` drew them from the demo shop's own piece tags. Each has
a label file (`demo-box-N.json`) giving the box's corners, and each piece's
place, tag and product. Box 1 is 15 tagged pairs of earrings on white cards,
box 2 is untagged earrings, and box 3 is sets.

The guide uses them in three ways:

1. **App screenshots** use the sample boxes, opened with
   `-demo-boxes -box capture|review|tags -sample 1|2|3`. These cover the
   capture, the box review with its markers, the piece sheet, the tag scan and
   the To identify queue.
2. **Explanatory figures** are drawn in R from the same photos. R reads a
   sample photo and its label file, and draws over it with ggplot:
   - piece outlines and numbers;
   - a piece that may be two ("Make it 2");
   - something that is not a piece;
   - the tray grid.
3. **Plain diagrams** are drawn in R with no photo, where a photo would get in
   the way. Examples are "the app counts cards, not loose pieces" and "touching
   pieces get a warning, never a guessed split".

The R simulation reads the same label files. So when the guide says "Box 1
added 15 pairs", the number comes from the box in the picture.

Rules for every box picture:

- Each is captioned as a drawn example, never presented as a real shop's box.
- The chapters on box counting say what the testers' note says: photo counting
  has not yet been measured on real boxes.
- The guide holds copies of the photos made smaller for the web (about
  1,200 px), in `images/boxes/`. The originals stay where the app keeps them.
- Pictures with pieces drawn over them use the same colours as the app's
  markers, so a reader recognises them on the phone.
- If the app's sample boxes change, the copies and figures are made again
  (`check_sources.R` watches `Jholok/DevTools/DemoBoxes/`).

## The guide's outline

Each chapter has the same parts:

1. **What you'll learn** (3 lines).
2. **The idea**: the background concept, in plain words.
3. **In the app**: steps with screenshots.
4. **Why it works this way**: the design reason.
5. **How it works**: what happens underneath, without code.
6. **Try it**: a worked example using the simulated shop.
7. **Remember**: a short summary.

Each chapter is marked "for everyone", "for counters" or "for the owner and approvers".

| # | Chapter | Main ideas |
|---|---|---|
| 0 | Welcome and how to use this guide | Who it's for, the demo shop, how the guide matches app versions |
| 1 | Stock basics | Products and SKUs, types and units (pairs, sets, pieces), cost, price and stock value |
| 2 | The ledger: why stock is a sum | Movements, why no stock number is ever typed in, the audit trail |
| 3 | Counting and reconciliation | Physical counts, blind counting, expected vs counted, short and over, shrinkage, when to adjust |
| 4 | Setting up the shop | Install, Face ID lock, shop details, product types, people and PINs, roles |
| 5 | The catalogue | Adding products, photos and drawings, importing a spreadsheet, barcodes and piece tags, the tag list |
| 6 | Recording movements | Received, sold, returned, adjustment, send out (jangad, karigar, order), back in |
| 7 | Reading the Overview | Stock worth, stock by type, needs attention, sales and festivals, best sellers, honest summaries |
| 8 | A count from start to finish | New count, scope, who's counting, the counting screen, Find by code, Undo, Clear |
| 9 | Counting boxes: tags and photos | Scan tags, box photo, the box review, markers, Make it 2, Not a piece, adding a box, repeated boxes |
| 10 | Pieces to identify later | The To identify queue, lookalikes, Not in the catalogue, why the count can't be completed until they're done |
| 11 | Book stock | Loading the billing system's file, "as of", status words, tags not found, sold during the count |
| 12 | Stock off the shelf and the cut-off | Places (shop, jangad, karigar, order), counting windows, moves during a count, cut-off corrections |
| 13 | Submit, review and complete | Submitting, who may approve, recount first, ticks, Set to zero, the signature, reopening |
| 14 | Results and the count report | Result, the PDF report, fingerprints, CSV exports |
| 15 | Keeping data safe | Backups and restore, the lock, exports asking the owner, diagnostics |
| 16 | Stories from the shop | Use cases: the first full count, a monthly showcase count, after Diwali, a missing pair, a new staff member, the karigar's return |
| A | Glossary | Every term, with the chapter that explains it |
| B | Questions and answers, and what to do when something goes wrong | |
| C | What changed | Per guide release |

## Phases

| Phase | What | Done when |
|---|---|---|
| 0. Set up | Install lintr and styler (Quarto comes with RStudio). Create the R project, `renv`, `_quarto.yml`, the style files and an empty book that renders. | `quarto render` builds an empty book with the theme. |
| 1. Simulated shop | Write the R simulation of the demo shop: catalogue, a year of movements, counts with errors, and reconciliation. Add tests for the rules above. | Tests pass, and the R shop's totals match the app's demo on the same dates. |
| 2. Screenshots and box pictures | Write the capture script and take the first set (about 40 screens: setup, catalogue, counting, review, result), then the box screens from the three sample boxes. Write the R code that reads the sample boxes and draws the box figures and diagrams. | The images are in `images/app/`, named after their screen, and the box figures render from R. |
| 3. Foundations | Write chapters 0 to 3 and the glossary: the concepts, with R charts and tables. | You have read them and agreed the tone and depth. **Review point.** |
| 4. Daily use | Write chapters 4 to 8. | |
| 5. Box counting | Write chapters 9 and 10, with the box screenshots. | |
| 6. Books, places, review | Write chapters 11 to 14. | |
| 7. Safety and stories | Write chapters 15 and 16, and appendices B and C. | |
| 8. Check and ship | Run the rule check against `CLAUDE.md`, a plain-language pass, check links and alt text, run lintr. Build the book and the single-file HTML. | Release 1 is ready to send. **Review point.** |
| 9. Keep it current | Add `check_sources.R` and a note in `CLAUDE.md` that a feature change updates its chapter. | The check lists stale chapters. |

Phase 3 is the first point where you see real content. It sets the tone for the rest, so the plan stops there for your review before going on.

## Risks

| Risk | What we do about it |
|---|---|
| The guide states a rule wrongly | Each chapter lists its sources. Phase 8 checks every rule against `CLAUDE.md` and the design documents. |
| Screens change after screenshots are taken | Screenshots are taken by script, so retaking them takes minutes. `check_sources.R` flags changed screens. |
| Worked examples and screenshots disagree | The R shop copies the app's demo shop (D3, phase 1). |
| A drawn box photo is taken for a real one, or suggests photo counting is proven | Every box picture is captioned as a drawn example, and the box chapters say photo counting is unmeasured on real boxes (D9). |
| The guide promises more than the app does | Photo counting is described as unmeasured on real boxes, and planned features (X1 values) are marked "coming". |
| Language drifts into jargon | Each term is explained the first time it appears and is in the glossary. Phase 8 includes a plain-language pass. |
| The guide is too long to read | Each chapter starts with "What you'll learn" and ends with "Remember", and counters can follow their own path. |
