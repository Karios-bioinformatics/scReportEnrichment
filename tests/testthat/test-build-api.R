# Test: build_screport_enrichment() — Public API ==============================
#
# Tests the full public API end-to-end for all supported input types.
# Covers: single df, named list, special chars, param validation,
# multi-comparison, empty input.

context("Public API")

fixture_dir <- "fixtures"

# ---- Parameter validation ----

test_that("top_n validation", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  expect_error(build_screport_enrichment(df, top_n = 0), ">= 1")
  expect_error(build_screport_enrichment(df, top_n = NA_integer_), "finite")
  expect_error(build_screport_enrichment(df, top_n = -1), ">= 1")
})

test_that("p_adjust_cutoff validation", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  expect_error(build_screport_enrichment(df, p_adjust_cutoff = 0), "in (0, 1]")
  expect_error(build_screport_enrichment(df, p_adjust_cutoff = 1.5), "in (0, 1]")
  expect_error(build_screport_enrichment(df, p_adjust_cutoff = NA_real_), "finite")
})

test_that("output_file validation", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  expect_error(build_screport_enrichment(df, output_file = ""), "non-empty")
  expect_warning(build_screport_enrichment(df, output_file = tempfile(fileext = ".txt")),
                 "does not end with")
})

test_that("self_contained validation", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  expect_error(build_screport_enrichment(df, self_contained = NA), "logical")
  expect_error(build_screport_enrichment(df, self_contained = "yes"), "logical")
})


# ---- Basic API ----

test_that("single data.frame produces valid report", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  result <- build_screport_enrichment(df, output_file = tempfile(fileext = ".html"),
                                      title = "Test Report", self_contained = FALSE)
  expect_true(file.exists(result[["output_file"]]))
  expect_s3_class(result[["enrichment"]], "data.frame")
  expect_equal(nrow(result[["enrichment"]]), 10)
  result_ids <- result[["enrichment"]][["result_id"]]
  expect_equal(length(unique(result_ids)), length(result_ids))
  unlink(result[["output_file"]])
})


# ---- Multi-comparison named list ----

test_that("named list produces globally-unique IDs via public API", {
  df1 <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[1:3, ]
  df2 <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[4:6, ]

  result <- build_screport_enrichment(
    enrichment = list(B_cell = df1, T_cell = df2),
    output_file = tempfile(fileext = ".html"),
    self_contained = FALSE
  )

  enr <- result[["enrichment"]]
  ids <- enr[["result_id"]]
  expect_equal(length(ids), length(unique(ids)))
  expect_true(any(grepl("B_cell__ORA_", ids)))
  expect_true(any(grepl("T_cell__ORA_", ids)))

  # term_details keys match result_id count
  model <- result[["model"]]
  expect_equal(length(model[["term_details"]]), nrow(enr))
  expect_setequal(names(model[["term_details"]]), ids)

  expect_true(file.exists(result[["output_file"]]))
  unlink(result[["output_file"]])
})


# ---- Special characters ----

test_that("special characters in title and data don't break output", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[1:2, ]
  df[["term_name"]][1] <- '</script><script>alert("x")</script>'

  result <- build_screport_enrichment(
    enrichment = df,
    title = 'A <B> & "C"',
    metadata = list(notes = "A&B <test>"),
    output_file = tempfile(fileext = ".html"),
    self_contained = FALSE
  )

  html <- paste(readLines(result[["output_file"]], warn = FALSE), collapse = "\n")

  # No executable script from user data
  expect_false(grepl('<script>alert', html, fixed = TRUE))
  # Payload tag not prematurely closed
  expect_false(grepl('</script>.*type="application/json"', html))
  # Title is HTML-escaped
  expect_match(html, "&lt;B&gt;", all = FALSE)

  unlink(result[["output_file"]])
})

test_that("comparison with special characters works", {
  df1 <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[1:2, ]
  df2 <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)[3:4, ]

  result <- build_screport_enrichment(
    enrichment = list("B cell's up" = df1, "T_cell/activated" = df2),
    output_file = tempfile(fileext = ".html"),
    self_contained = FALSE
  )

  enr <- result[["enrichment"]]
  ids <- enr[["result_id"]]
  expect_equal(length(ids), length(unique(ids)))
  expect_true(file.exists(result[["output_file"]]))
  unlink(result[["output_file"]])
})


# ---- Empty input ----

test_that("empty input produces valid HTML", {
  df <- empty_ora_table()
  result <- build_screport_enrichment(df, output_file = tempfile(fileext = ".html"),
                                      self_contained = FALSE)
  html <- paste(readLines(result[["output_file"]], warn = FALSE), collapse = "\n")
  expect_true(grepl("empty-state", html) || grepl("No enrichment terms", html))
  expect_true(grepl("sr-payload", html))
  unlink(result[["output_file"]])
})


# ---- Output directory auto-creation ----

test_that("output directory is auto-created", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  tmp <- file.path(tempdir(), "scReport_test_subdir", "out.html")
  result <- build_screport_enrichment(df, output_file = tmp, self_contained = FALSE)
  expect_true(file.exists(tmp))
  unlink(tmp)
  unlink(dirname(tmp), recursive = TRUE)
})


# ---- column_map via public API ----

test_that("column_map works through public API", {
  df <- data.frame(
    pathway_id = "P1", pathway = "Test",
    padj = 0.001, n_genes = 5, gene_list = "A/B",
    stringsAsFactors = FALSE
  )
  result <- build_screport_enrichment(
    df,
    column_map = c(term_id = "pathway_id", term_name = "pathway",
                   p_adjust = "padj", gene_count = "n_genes",
                   gene_ids_raw = "gene_list"),
    output_file = tempfile(fileext = ".html"),
    self_contained = FALSE
  )
  enr <- result[["enrichment"]]
  expect_equal(enr[["term_id"]], "P1")
  expect_equal(enr[["p_adjust"]], 0.001)
  unlink(result[["output_file"]])
})
