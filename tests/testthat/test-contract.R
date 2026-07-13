# Test: user result_id contract + ORA_MAPPABLE_COLS ============================

context("User result_id Contract")

fixture_dir <- "fixtures"

test_that("user input result_id is ignored, internal IDs are generated", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[1:3, ]
  df[["result_id"]] <- c("duplicate", "duplicate", "unique")

  expect_warning(
    result <- normalize_input(df),
    "contains a 'result_id' column"
  )
  ids <- result[["result_id"]]
  expect_equal(length(ids), length(unique(ids)))
  expect_false("duplicate" %in% ids)
})

test_that("column_map with result_id target gives clear error", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  df[["my_id"]] <- paste0("ID_", seq_len(nrow(df)))

  expect_error(
    normalize_input(df, column_map = c(result_id = "my_id")),
    "cannot be mapped"
  )
})

test_that("column_map with gene_ratio_num target gives error", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  df[["gr"]] <- 0.05

  expect_error(
    normalize_input(df, column_map = c(gene_ratio_num = "gr")),
    "not allowed"
  )
})

test_that("column_map with genes target gives error", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  df[["g"]] <- "A/B"

  expect_error(
    normalize_input(df, column_map = c(genes = "g")),
    "not allowed"
  )
})

test_that("ORA_MAPPABLE_COLS excludes derived/internal fields", {
  expect_false("result_id" %in% ORA_MAPPABLE_COLS)
  expect_false("gene_ratio_num" %in% ORA_MAPPABLE_COLS)
  expect_false("background_ratio_num" %in% ORA_MAPPABLE_COLS)
  expect_false("genes" %in% ORA_MAPPABLE_COLS)
  expect_true("gene_ids_raw" %in% ORA_MAPPABLE_COLS)
  # Check important ones ARE mappable
  expect_true("term_id" %in% ORA_MAPPABLE_COLS)
  expect_true("p_adjust" %in% ORA_MAPPABLE_COLS)
  expect_true("gene_ratio" %in% ORA_MAPPABLE_COLS)
})

test_that("internal schema remains 17 columns", {
  expect_equal(length(ORA_ALL_COLS), 17L)
})
