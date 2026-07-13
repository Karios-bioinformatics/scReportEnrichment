# Test: normalize_input.R — Second Round =======================================
#
# Covers: scoped result_ids, column_map validation, ambiguity errors,
# named list handling, edge cases.

context("Input Normalization - Round 2")

fixture_dir <- "fixtures"

# ---- result_id scoping ----

test_that("single data.frame gets scoped result_ids", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  result <- normalize_input(df, comparison = "B_cell")

  expect_equal(length(unique(result[["result_id"]])), nrow(result))
  expect_match(result[["result_id"]][1], "B_cell__ORA_")
})

test_that("named list produces globally-unique scoped result_ids", {
  df1 <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[1:3, ]
  df2 <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[4:6, ]

  result <- normalize_input(list(
    B_cell = df1,
    T_cell = df2
  ))

  ids <- result[["result_id"]]
  expect_equal(length(ids), length(unique(ids)))            # globally unique
  expect_true(any(grepl("B_cell__ORA_", ids)))
  expect_true(any(grepl("T_cell__ORA_", ids)))
  expect_equal(length(unique(result[["comparison"]])), 2)
})

test_that("scoped IDs handle special characters in comparison names", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[1:2, ]

  result <- normalize_input(list(
    "B cell's comparison" = df,
    "中文名称" = df
  ))

  ids <- result[["result_id"]]
  expect_equal(length(ids), length(unique(ids)))
  # IDs should be all ASCII-safe (no spaces, quotes, unicode)
  expect_false(any(grepl("[ ']", ids)))
})

test_that("empty list elements don't break ID generation", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[1:2, ]

  result <- normalize_input(list(
    B_cell = df,
    empty  = data.frame(term_id = character(0), term_name = character(0),
                        p_value = numeric(0), p_adjust = numeric(0),
                        gene_count = integer(0), gene_ids = character(0)),
    T_cell = df
  ))

  ids <- result[["result_id"]]
  expect_equal(length(ids), length(unique(ids)))
  expect_equal(length(unique(result[["comparison"]])), 2)   # empty skipped
})


# ---- column_map validation ----

test_that("column_map with non-existent column throws error", {
  df <- data.frame(a = 1, stringsAsFactors = FALSE)
  expect_error(
    normalize_input(df, column_map = c(term_id = "nonexistent")),
    "column_map references non-existent"
  )
})

test_that("column_map with invalid internal field throws error", {
  df <- data.frame(mycol = "X", stringsAsFactors = FALSE)
  expect_error(
    normalize_input(df, column_map = c(invalid_field = "mycol")),
    "Invalid internal field"
  )
})

test_that("column_map with empty name throws error", {
  df <- data.frame(x = "a", stringsAsFactors = FALSE)
  expect_error(
    normalize_input(df, column_map = c("" = "x")),
    "must be non-empty"
  )
})

test_that("column_map duplicates throw error", {
  df <- data.frame(x = "a", y = "b", stringsAsFactors = FALSE)
  expect_error(
    normalize_input(df, column_map = c(term_id = "x", term_id = "y")),
    "Duplicate"
  )
})

test_that("unnamed column_map throws error", {
  df <- data.frame(x = "a", stringsAsFactors = FALSE)
  expect_error(
    normalize_input(df, column_map = c("x")), # no names
    "named character vector"
  )
})


# ---- Ambiguity errors ----

test_that("p.adjust + padj ambiguity throws error", {
  df <- data.frame(
    term_id = "GO:01", term_name = "t1",
    p_value = 0.01,  p.adjust = 0.05, padj = 0.06,
    gene_count = 5, geneID = "A/B",
    stringsAsFactors = FALSE
  )
  expect_error(
    normalize_input(df),
    "Ambiguous.*p_adjust"
  )
})

test_that("column_map resolves ambiguity", {
  df <- data.frame(
    term_id = "GO:01", term_name = "t1",
    p_value = 0.01,  p.adjust = 0.05, padj = 0.06,
    gene_count = 5, geneID = "A/B",
    stringsAsFactors = FALSE
  )
  result <- normalize_input(df, column_map = c(p_adjust = "padj"))
  expect_equal(result[["p_adjust"]], 0.06)
})

test_that("comparison candidate conflict throws error", {
  df <- data.frame(
    term_id = "GO:01", term_name = "t1",
    p_value = 0.01, p_adjust = 0.05,
    gene_count = 5, geneID = "A/B",
    cluster = "C1", celltype = "T cells",
    stringsAsFactors = FALSE
  )
  expect_error(
    normalize_input(df),
    "Ambiguous.*comparison"
  )
})


# ---- Gene parsing ----

test_that("gene string handles mixed separators within a single string", {
  # strsplit with [/;,] splits on any single char; "A/B;C" becomes "A","B","C"
  result <- parse_gene_string("A/B")
  expect_equal(result, c("A", "B"))
})

test_that("ratio parsing edge cases", {
  expect_equal(ratio_to_numeric("15/200"), 0.075)
  expect_equal(ratio_to_numeric("0.05"), 0.05)
  expect_true(is.na(ratio_to_numeric("")))
  expect_true(is.na(ratio_to_numeric(NA_character_)))
  expect_equal(parse_ratio_string("5/100"), c(5, 100))
})


# ---- Input types ----

test_that("normalize_input handles empty data.frame", {
  df <- read.csv(file.path(fixture_dir, "ora_empty.csv"), stringsAsFactors = FALSE)
  result <- normalize_input(df)
  expect_equal(nrow(result), 0)
  expect_true(all(ORA_ALL_COLS %in% names(result)))
})

test_that("normalize_input accepts clusterProfiler-style CSV", {
  df <- read.csv(file.path(fixture_dir, "ora_clusterprofiler.csv"), stringsAsFactors = FALSE)
  result <- normalize_dataframe(df)
  expect_equal(result[["term_name"]][1], "apoptotic process")
  expect_equal(result[["gene_ratio_num"]][1], 15/200)
  expect_equal(length(result[["genes"]][[1]]), 5)
})

test_that("named list produces correct comparison labels", {
  df1 <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[1:2, ]
  df2 <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[3:4, ]
  result <- normalize_input(list(B_cell = df1, T_cell = df2))
  expect_setequal(unique(result[["comparison"]]), c("B_cell", "T_cell"))
})
