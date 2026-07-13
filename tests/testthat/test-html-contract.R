# Test: HTML Contract — Third Round ============================================
#
# Covers: no external resource refs in self-contained, precise CSS/JS counts,
# no on*= events, no nested tags, no placeholders, parseable payload.

context("HTML Contract - Round 3")

fixture_dir <- "fixtures"

test_that("self-contained output has no external resource references", {
  skip_if_not_installed("plotly")

  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  result <- build_screport_enrichment(
    df, output_file = tempfile(fileext = ".html"), self_contained = TRUE
  )
  html <- paste(readLines(result[["output_file"]], warn = FALSE), collapse = "\n")

  # No external resource attributes
  expect_false(grepl('<script[^>]*src=["\\]https?://', html, perl = TRUE))
  expect_false(grepl('<link[^>]*href=["\\]https?://', html, perl = TRUE))
  expect_false(grepl('<img[^>]*src=["\\]https?://', html, perl = TRUE))
  expect_false(grepl('<source[^>]*src=["\\]https?://', html, perl = TRUE))
  expect_false(grepl('<iframe[^>]*src=["\\]https?://', html, perl = TRUE))

  unlink(result[["output_file"]])
})

test_that("Plotly dependency appears exactly once in self-contained output", {
  skip_if_not_installed("plotly")

  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  result <- build_screport_enrichment(
    df, output_file = tempfile(fileext = ".html"), self_contained = TRUE
  )
  html <- paste(readLines(result[["output_file"]], warn = FALSE), collapse = "\n")

  # Count inline script tags containing Plotly (the newPlot reference)
  plotly_count <- count_fixed(html, "Plotly.newPlot")
  expect_equal(plotly_count, 1L)

  unlink(result[["output_file"]])
})

test_that("each own JS file appears exactly once", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  result <- build_screport_enrichment(
    df, output_file = tempfile(fileext = ".html"), self_contained = FALSE
  )
  html <- paste(readLines(result[["output_file"]], warn = FALSE), collapse = "\n")

  expect_equal(count_fixed(html, "scReportEnrichment v0.1.0: Core JS"), 1L)
  expect_equal(count_fixed(html, "scReportEnrichment v0.1.0: Plot Utils"), 1L)
  expect_equal(count_fixed(html, "scReportEnrichment v0.1.0: Enrichment Plots"), 1L)
  expect_equal(count_fixed(html, "scReportEnrichment: Term Table"), 1L)
  expect_equal(count_fixed(html, "scReportEnrichment: Term Detail"), 1L)

  # Plot Utils must appear before Enrichment Plots in the HTML
  utils_pos <- regexpr("scReportEnrichment v0.1.0: Plot Utils", html, fixed = TRUE)[1]
  plots_pos <- regexpr("scReportEnrichment v0.1.0: Enrichment Plots", html, fixed = TRUE)[1]
  expect_true(utils_pos > 0 && plots_pos > 0 && utils_pos < plots_pos,
              info = "Plot Utils should load before Enrichment Plots")

  unlink(result[["output_file"]])
})

test_that("CSS appears exactly once", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  result <- build_screport_enrichment(
    df, output_file = tempfile(fileext = ".html"), self_contained = FALSE
  )
  html <- paste(readLines(result[["output_file"]], warn = FALSE), collapse = "\n")

  expect_equal(count_fixed(html, "scReportEnrichment: Report Styles v0.1.0"), 1L)

  unlink(result[["output_file"]])
})

test_that("no on*= event attributes in output HTML", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  result <- build_screport_enrichment(
    df, output_file = tempfile(fileext = ".html"), self_contained = FALSE
  )
  html <- paste(readLines(result[["output_file"]], warn = FALSE), collapse = "\n")

  # Match any on*= attribute
  expect_false(grepl("\\son[a-z]+\\s*=", html, ignore.case = TRUE, perl = TRUE))

  unlink(result[["output_file"]])
})

test_that("no on*= in source templates and JS", {
  # Check template files
  tmpl_dir <- "../../inst/templates"
  tpl_files <- list.files(tmpl_dir, pattern = "\\.html$", recursive = TRUE, full.names = TRUE)
  for (f in tpl_files) {
    content <- paste(readLines(f, warn = FALSE), collapse = "\n")
    expect_false(grepl("\\son[a-z]+\\s*=", content, ignore.case = TRUE, perl = TRUE),
                 info = paste("on*= found in", f))
  }

  # Check JS files
  js_dir <- "../../inst/assets/js"
  js_files <- list.files(js_dir, pattern = "\\.js$", full.names = TRUE)
  for (f in js_files) {
    content <- paste(readLines(f, warn = FALSE), collapse = "\n")
    expect_false(grepl("\\son[a-z]+\\s*=", content, ignore.case = TRUE, perl = TRUE),
                 info = paste("on*= found in", f))
  }
})

test_that("no nested script/style tags", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  result <- build_screport_enrichment(
    df, output_file = tempfile(fileext = ".html"), self_contained = FALSE
  )
  html <- paste(readLines(result[["output_file"]], warn = FALSE), collapse = "\n")

  expect_false(grepl("<script><script", html, fixed = TRUE))
  expect_false(grepl("<style><style", html, fixed = TRUE))
  expect_false(grepl("<script><link", html, fixed = TRUE))
  expect_false(grepl("</script></script>", html, fixed = TRUE))

  unlink(result[["output_file"]])
})

test_that("no residual template placeholders", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  result <- build_screport_enrichment(
    df, output_file = tempfile(fileext = ".html"), self_contained = FALSE
  )
  html <- paste(readLines(result[["output_file"]], warn = FALSE), collapse = "\n")

  expect_false(grepl("\\{\\{[^}]+\\}\\}", html))

  unlink(result[["output_file"]])
})

test_that("no NA/NaN/Inf bare tokens in HTML", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  result <- build_screport_enrichment(
    df, output_file = tempfile(fileext = ".html"), self_contained = FALSE
  )
  html <- paste(readLines(result[["output_file"]], warn = FALSE), collapse = "\n")

  expect_false(grepl("\\bNaN\\b", html))
  expect_false(grepl("\\bInf\\b", html))

  unlink(result[["output_file"]])
})

test_that("JSON payload is parseable", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  result <- build_screport_enrichment(
    df, output_file = tempfile(fileext = ".html"), self_contained = FALSE
  )
  html <- paste(readLines(result[["output_file"]], warn = FALSE), collapse = "\n")

  payload_match <- regmatches(html, regexec(
    '<script id="sr-payload" type="application/json">(.*?)</script>', html
  ))[[1]]
  expect_true(length(payload_match) >= 2)

  payload_json <- payload_match[2]
  payload_json <- gsub("\\\\u003c", "<", payload_json, fixed = TRUE)
  payload_json <- gsub("\\\\u003e", ">", payload_json, fixed = TRUE)
  payload_json <- gsub("\\\\u0026", "&", payload_json, fixed = TRUE)
  model <- jsonlite::fromJSON(payload_json)
  expect_true("overview" %in% names(model))

  unlink(result[["output_file"]])
})

test_that("renderer script contains data-result-id contract", {
  df <- read.csv(file.path(fixture_dir, "ora_generic.csv"), stringsAsFactors = FALSE)
  result <- build_screport_enrichment(
    df, output_file = tempfile(fileext = ".html"), self_contained = FALSE
  )
  html <- paste(readLines(result[["output_file"]], warn = FALSE), collapse = "\n")

  expect_match(html, "data-result-id=")

  unlink(result[["output_file"]])
})

test_that("empty result produces valid page", {
  df <- empty_ora_table()
  result <- build_screport_enrichment(
    df, output_file = tempfile(fileext = ".html"), self_contained = FALSE
  )
  html <- paste(readLines(result[["output_file"]], warn = FALSE), collapse = "\n")
  expect_match(html, "sr-payload")
  expect_match(html, "sidebar")
  unlink(result[["output_file"]])
})
