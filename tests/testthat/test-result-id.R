# Test: result_id generation — fourth round ====================================

context("Result ID Generation - Round 4")

fixture_dir <- "fixtures"

# ---- stable_hash6 correctness ----

test_that("stable_hash6 always outputs 6 lowercase hex characters", {
  expect_match(stable_hash6("B cell"), "^[0-9a-f]{6}$")
  expect_equal(nchar(stable_hash6("B cell")), 6L)
})

test_that("stable_hash6 handles chinese characters", {
  expect_match(stable_hash6("\u4e2d\u6587\u4e00"), "^[0-9a-f]{6}$")
  expect_match(stable_hash6("\u4e2d\u6587\u4e8c"), "^[0-9a-f]{6}$")
  expect_false(stable_hash6("\u4e2d\u6587\u4e00") == stable_hash6("\u4e2d\u6587\u4e8c"))
})

test_that("stable_hash6 handles very long input", {
  long_text <- paste(rep("long comparison \u4e2d\u6587 123", 1000), collapse = "")
  expect_match(stable_hash6(long_text), "^[0-9a-f]{6}$")
  expect_false(is.na(stable_hash6(long_text)))
})

test_that("stable_hash6 is deterministic", {
  expect_equal(stable_hash6("same input"), stable_hash6("same input"))
  expect_equal(stable_hash6("B cell"), stable_hash6("B cell"))
})

test_that("stable_hash6 handles edge cases", {
  expect_equal(stable_hash6(NULL), "000000")
  expect_equal(stable_hash6(NA_character_), "000000")
  expect_equal(stable_hash6(""), "000000")
})

test_that("stable_hash6 length != 1 produces 000000", {
  expect_equal(stable_hash6(c("a", "b")), "000000")
})


# ---- make_scoped_result_ids real collision ----

test_that("collision with identical comparison triggers _c1 suffix", {
  existing <- make_scoped_result_ids(n = 2, comparison = "B cell")

  new_ids <- make_scoped_result_ids(
    n = 2,
    comparison = "B cell",
    existing_ids = existing
  )

  all_ids <- c(existing, new_ids)
  expect_equal(length(all_ids), length(unique(all_ids)))
  expect_true(all(grepl("_c1$", new_ids)))
})

test_that("double collision triggers _c2 suffix", {
  existing <- make_scoped_result_ids(n = 2, comparison = "B cell")
  existing2 <- c(existing, sub("$", "_c1", existing))

  new_ids <- make_scoped_result_ids(
    n = 2,
    comparison = "B cell",
    existing_ids = existing2
  )

  all_ids <- c(existing2, new_ids)
  expect_equal(length(all_ids), length(unique(all_ids)))
  expect_true(all(grepl("_c2$", new_ids)))
})

test_that("comparisons that sanitise to same text produce different scopes", {
  ids1 <- make_scoped_result_ids(2, "B cell")
  ids2 <- make_scoped_result_ids(2, "B-cell")
  ids3 <- make_scoped_result_ids(2, "B/cell")

  ids_all <- c(ids1, ids2, ids3)
  expect_equal(length(ids_all), length(unique(ids_all)))

  expect_match(ids1[1], "^B_cell__")
  expect_match(ids2[1], "^B_cell__")
  expect_match(ids3[1], "^B_cell__")

  hash1 <- sub("^B_cell__([a-f0-9]+)__.*", "\\1", ids1[1])
  hash2 <- sub("^B_cell__([a-f0-9]+)__.*", "\\1", ids2[1])
  hash3 <- sub("^B_cell__([a-f0-9]+)__.*", "\\1", ids3[1])
  expect_false(hash1 == hash2 && hash2 == hash3)
})

test_that("chinese comparison names produce valid scopes", {
  ids1 <- make_scoped_result_ids(2, "\u4e2d\u6587\u4e00")
  ids2 <- make_scoped_result_ids(2, "\u4e2d\u6587\u4e8c")
  ids_all <- c(ids1, ids2)
  expect_equal(length(ids_all), length(unique(ids_all)))

  expect_match(ids1[1], "^group__")
  expect_match(ids2[1], "^group__")

  hash1 <- sub("^group__([a-f0-9]+)__.*", "\\1", ids1[1])
  hash2 <- sub("^group__([a-f0-9]+)__.*", "\\1", ids2[1])
  expect_false(hash1 == hash2)
})

test_that("result_ids never contain spaces, quotes, or angle brackets", {
  ids <- make_scoped_result_ids(5, "B cell's <test>")
  for (pat in c(" ", "'", "\"", "<", ">", "&")) {
    expect_false(any(grepl(pat, ids, fixed = TRUE)),
                 info = paste("IDs contain forbidden char:", pat))
  }
})

test_that("make_scoped_result_ids is reproducible", {
  expect_equal(
    make_scoped_result_ids(3, "MyTestComparison"),
    make_scoped_result_ids(3, "MyTestComparison")
  )
})

# ---- Public API multi-comparison ----

test_that("public API with colliding sanitised names succeeds", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[1:2, ]

  result <- build_screport_enrichment(
    enrichment = list("B cell" = df, "B-cell" = df, "B/cell" = df),
    output_file = tempfile(fileext = ".html"),
    self_contained = FALSE
  )

  ids <- result[["enrichment"]][["result_id"]]
  expect_equal(length(ids), length(unique(ids)))
  expect_equal(length(unique(result[["enrichment"]][["comparison"]])), 3)
  expect_true(file.exists(result[["output_file"]]))
  unlink(result[["output_file"]])
})

test_that("public API with chinese names succeeds", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[1:2, ]

  result <- build_screport_enrichment(
    enrichment = list("\u4e2d\u6587\u4e00" = df, "\u4e2d\u6587\u4e8c" = df),
    output_file = tempfile(fileext = ".html"),
    self_contained = FALSE
  )

  ids <- result[["enrichment"]][["result_id"]]
  expect_equal(length(ids), length(unique(ids)))
  unlink(result[["output_file"]])
})

test_that("term_details keys match all result_ids exactly", {
  df1 <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[1:3, ]
  df2 <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[4:6, ]

  result <- build_screport_enrichment(
    enrichment = list(B_cell = df1, T_cell = df2),
    output_file = tempfile(fileext = ".html"),
    self_contained = FALSE
  )

  enr_ids <- result[["enrichment"]][["result_id"]]
  detail_keys <- names(result[["model"]][["term_details"]])
  expect_setequal(enr_ids, detail_keys)
  unlink(result[["output_file"]])
})
