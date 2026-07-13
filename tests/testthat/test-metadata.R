# Test: validate_metadata.R — Second Round =====================================

context("Metadata Validation - Round 2")

test_that("defaults are populated", {
  meta <- validate_metadata(list())
  expect_equal(meta[["analysis_type"]], "ORA")
  expect_true(all(METADATA_FIELDS %in% names(meta)))
})

test_that("user values override defaults", {
  meta <- validate_metadata(list(
    species       = "Homo sapiens",
    gene_id_type  = "SYMBOL",
    analysis_tool = "clusterProfiler"
  ))
  expect_equal(meta[["species"]], "Homo sapiens")
  expect_equal(meta[["gene_id_type"]], "SYMBOL")
})

test_that("unknown fields warn", {
  expect_warning(validate_metadata(list(invalid = "x")), "Unknown metadata field")
})

test_that("mapping_rate computed from counts", {
  meta <- validate_metadata(list(input_gene_count = 1000, mapped_gene_count = 850))
  expect_equal(meta[["mapping_rate"]], 0.85)
})

test_that("low mapping rate warns", {
  warnings <- capture_warnings(validate_metadata(list(mapping_rate = 0.3)))
  expect_true(any(grepl("Mapping rate", warnings)))
})

test_that("invalid p_adjust_cutoff warns", {
  expect_warning(validate_metadata(list(p_adjust_cutoff = 2)), "p_adjust_cutoff")
})

test_that("generated_at is auto-populated", {
  meta <- validate_metadata(list())
  expect_false(is.na(meta[["generated_at"]]))
})

test_that("non-list input errors", {
  expect_error(validate_metadata("not_a_list"), "must be a named list")
})
