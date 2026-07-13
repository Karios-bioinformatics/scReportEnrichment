# Test: build_report_model.R — Second Round ====================================

context("Report Model - Round 2")

fixture_dir <- "fixtures"

test_that("report model has correct structure", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  df_norm <- normalize_input(df)
  meta <- validate_metadata(list(species = "Homo sapiens"))
  model <- build_report_model(df_norm, meta, top_n = 5L, p_adjust_cutoff = 0.05)

  expect_s3_class(model, "scReportEnrichment_model")
  top_fields <- c("title", "generation_time", "overview", "comparisons",
                  "dot_plot", "bar_plot", "term_table", "term_details",
                  "top_n", "p_adjust_cutoff", "warnings")
  for (f in top_fields) {
    expect_true(f %in% names(model), info = paste("Missing:", f))
  }
})

test_that("overview statistics are correct", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  df_norm <- normalize_input(df)
  model <- build_report_model(df_norm, validate_metadata(list()), top_n = 5)

  ov <- model[["overview"]]
  expect_equal(ov[["n_total_terms"]], 10)
  expect_gt(ov[["n_significant"]], 0)
})

test_that("dot_plot sends ALL significant terms (no global top_n)", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  df_norm <- normalize_input(df)
  model <- build_report_model(df_norm, validate_metadata(list()),
                              p_adjust_cutoff = 0.05)

  # All 10 terms have p_adjust < 0.05 in the fixture, so expect 10
  # but some might be exactly at 0.04 which IS < 0.05
  n_sig <- sum(df_norm[["p_adjust"]] < 0.05 & !is.na(df_norm[["p_adjust"]]))
  expect_equal(nrow(model[["dot_plot"]]), n_sig)
  expect_equal(nrow(model[["bar_plot"]]), n_sig)
})

test_that("top_n is stored in model for front-end use", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  df_norm <- normalize_input(df)
  model <- build_report_model(df_norm, validate_metadata(list()), top_n = 7L)
  expect_equal(model[["top_n"]], 7L)
})

test_that("term_details keys match result_ids", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  df_norm <- normalize_input(df)
  model <- build_report_model(df_norm, validate_metadata(list()))
  expect_setequal(names(model[["term_details"]]), df_norm[["result_id"]])
})

test_that("term_detail has correct fields", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  df_norm <- normalize_input(df)
  model <- build_report_model(df_norm, validate_metadata(list()))
  d <- model[["term_details"]][[1]]
  expect_true("term_id" %in% names(d))
  expect_true("term_name" %in% names(d))
  expect_true("genes" %in% names(d))
  expect_true("n_genes" %in% names(d))
})

test_that("empty input produces valid model", {
  df <- empty_ora_table()
  model <- build_report_model(df, validate_metadata(list()))
  expect_true(model[["empty_result"]])
  expect_equal(model[["overview"]][["n_total_terms"]], 0)
  expect_equal(nrow(model[["dot_plot"]]), 0)
})

test_that("multi-comparison model has correct comparison lists", {
  df1 <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[1:3, ]
  df2 <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[4:6, ]
  df_norm <- normalize_input(list(B_cell = df1, T_cell = df2))
  model <- build_report_model(df_norm, validate_metadata(list()))

  expect_setequal(unlist(model[["comparisons"]]), c("B_cell", "T_cell"))
  expect_equal(model[["overview"]][["n_comparisons"]], 2)
  expect_equal(nrow(model[["term_table"]]), 6)
})
