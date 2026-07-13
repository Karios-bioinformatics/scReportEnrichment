# Test: validate_input.R — Second Round ========================================

context("Input Validation - Round 2")

test_that("valid data passes silently", {
  df <- empty_ora_table(3)
  df[["result_id"]] <- c("ORA_001", "ORA_002", "ORA_003")
  df[["comparison"]] <- c("A", "A", "B")
  df[["database"]] <- c("GO", "GO", "GO")
  df[["term_id"]] <- c("GO:01", "GO:02", "GO:03")
  df[["term_name"]] <- c("term1", "term2", "term3")
  df[["p_value"]] <- c(0.001, 0.01, 0.05)
  df[["p_adjust"]] <- c(0.01, 0.05, 0.1)
  df[["gene_ratio_num"]] <- c(0.05, 0.08, 0.12)
  df[["background_ratio_num"]] <- c(0.01, 0.02, 0.03)
  df[["gene_count"]] <- c(10L, 15L, 20L)
  df[["genes"]] <- list(c("A","B"), c("C","D"), c("E"))

  warnings <- validate_input(df, p_adjust_cutoff = 0.05)
  expect_type(warnings, "character")
})

test_that("missing required columns throws descriptive error", {
  df <- data.frame(a = 1)
  expect_error(validate_input(df), "Missing required columns")
})

test_that("p-value > 1 throws error", {
  df <- empty_ora_table(1)
  df[["result_id"]] <- "ORA_001"
  df[["comparison"]] <- "A"; df[["database"]] <- "GO"
  df[["term_id"]] <- "GO:01"; df[["term_name"]] <- "t1"
  df[["p_value"]] <- 1.5; df[["p_adjust"]] <- 0.05
  df[["gene_count"]] <- 10L; df[["genes"]] <- list(c("A","B"))
  expect_error(validate_input(df), "outside")
})

test_that("negative gene_count throws error", {
  df <- empty_ora_table(1)
  df[["result_id"]] <- "ORA_001"
  df[["comparison"]] <- "A"; df[["database"]] <- "GO"
  df[["term_id"]] <- "GO:01"; df[["term_name"]] <- "t1"
  df[["p_value"]] <- 0.01; df[["p_adjust"]] <- 0.05
  df[["gene_count"]] <- -5L; df[["genes"]] <- list(c("A"))
  expect_error(validate_input(df), "negative")
})

test_that("ratio outside [0,1] throws error", {
  df <- empty_ora_table(1)
  df[["result_id"]] <- "ORA_001"
  df[["comparison"]] <- "A"; df[["database"]] <- "GO"
  df[["term_id"]] <- "GO:01"; df[["term_name"]] <- "t1"
  df[["p_value"]] <- 0.01; df[["p_adjust"]] <- 0.05
  df[["gene_ratio_num"]] <- 1.5
  df[["gene_count"]] <- 1L; df[["genes"]] <- list(c("A"))
  expect_error(validate_input(df), "gene_ratio_num")
})

test_that("no significant terms generates warning", {
  df <- empty_ora_table(2)
  df[["result_id"]] <- c("ORA_001", "ORA_002")
  df[["comparison"]] <- c("A", "A"); df[["database"]] <- c("GO", "GO")
  df[["term_id"]] <- c("GO:01", "GO:02")
  df[["term_name"]] <- c("t1", "t2")
  df[["p_value"]] <- c(0.5, 0.6); df[["p_adjust"]] <- c(0.5, 0.6)
  df[["gene_count"]] <- c(5L, 10L)
  df[["genes"]] <- list(c("A"), c("B","C"))
  warnings <- validate_input(df, p_adjust_cutoff = 0.05)
  expect_true(any(grepl("No terms have p_adjust", warnings)))
})

test_that("zero p_adjust generates warning about capping", {
  df <- empty_ora_table(1)
  df[["result_id"]] <- "ORA_001"; df[["comparison"]] <- "A"
  df[["database"]] <- "GO"; df[["term_id"]] <- "GO:01"
  df[["term_name"]] <- "t1"
  df[["p_value"]] <- 0; df[["p_adjust"]] <- 0
  df[["gene_count"]] <- 1L; df[["genes"]] <- list(c("A"))
  warnings <- validate_input(df, p_adjust_cutoff = 0.05)
  expect_true(any(grepl("exactly 0", warnings)))
})

test_that("invalid direction values throw error", {
  df <- empty_ora_table(1)
  df[["result_id"]] <- "ORA_001"; df[["comparison"]] <- "A"
  df[["database"]] <- "GO"; df[["term_id"]] <- "GO:01"
  df[["term_name"]] <- "t1"
  df[["p_value"]] <- 0.01; df[["p_adjust"]] <- 0.05
  df[["gene_count"]] <- 1L; df[["genes"]] <- list(c("A"))
  df[["input_direction"]] <- "invalid_direction"
  expect_error(validate_input(df), "Invalid values in 'input_direction'")
})

test_that("duplicate result_id throws error", {
  df <- empty_ora_table(2)
  df[["result_id"]] <- c("ORA_001", "ORA_001")
  df[["comparison"]] <- c("A", "A"); df[["database"]] <- c("GO", "GO")
  df[["term_id"]] <- c("GO:01", "GO:02"); df[["term_name"]] <- c("t1", "t2")
  df[["p_value"]] <- c(0.001, 0.01); df[["p_adjust"]] <- c(0.01, 0.05)
  df[["gene_count"]] <- c(5L, 10L)
  df[["genes"]] <- list(c("A"), c("B","C"))
  expect_error(validate_input(df), "duplicate")
})
