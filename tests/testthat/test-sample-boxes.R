# The sample boxes, read from their label files, so the guide's words match
# the pictures.

test_that("each sample box holds what its label file says", {
  boxes <- sample_boxes()
  expect_equal(boxes$type, c("Earrings", "Earrings", "Sets"))
  expect_equal(boxes$unit, c("pair", "pair", "set"))
  expect_equal(boxes$pieces, c(15L, 15L, 11L))
  # Box 2 is the untagged box: every piece is left to identify.
  expect_equal(boxes$tags_read[2], 0L)
})

test_that("every piece in a sample box is a product of the shop", {
  pieces <- purrr::map(sample_box_numbers, sample_box_pieces) |>
    purrr::list_rbind()
  expect_true(all(pieces$sku %in% shop$products$sku))
  counts <- sample_box_counts(1, shop)
  expect_equal(sum(counts$pieces), 15L)
  expect_false(anyNA(counts$name))
})

test_that("the box's corners on the photo are where the label file says", {
  corners <- sample_box_corners(1)
  transform <- box_to_photo_transform(corners)
  mapped <- apply_transform(transform, c(0, 1, 1, 0), c(0, 0, 1, 1))
  expect_equal(mapped$x, corners$x, tolerance = 1e-9)
  expect_equal(mapped$y, corners$y, tolerance = 1e-9)
})

test_that("piece outlines land inside the box on the photo", {
  outlines <- pieces_on_photo(1)
  corners <- sample_box_corners(1)
  expect_true(all(outlines$x > min(corners$x) & outlines$x < max(corners$x)))
  expect_true(all(outlines$y > min(corners$y) & outlines$y < max(corners$y)))
})

test_that("every box picture says it is a drawn example", {
  expect_match(box_caption("Box 1."), "drawn example")
  expect_match(box_caption("Box 1."), "not a photo of a\\s+real shop's box")
})
