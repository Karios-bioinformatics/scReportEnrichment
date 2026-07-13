# Test: GSEA dispatcher order ==================================================

context("GSEA Type Checking Order")

test_that("gseaResult (single class) gets GSEA-specific error", {
  mock <- structure(list(), class = "gseaResult")
  expect_error(
    normalize_input(mock),
    "GSEA result objects are not supported"
  )
})

test_that("gseaResult mixed with enrichResult gets GSEA-specific error", {
  # gseaResult inherits from enrichResult in clusterProfiler
  mock <- structure(list(), class = c("gseaResult", "enrichResult"))
  expect_error(
    normalize_input(mock),
    "GSEA result objects are not supported"
  )
})

test_that("gseaResult inside a named list gets GSEA-specific error", {
  mock <- structure(list(), class = "gseaResult")
  expect_error(
    normalize_input(list(A = mock)),
    "GSEA result objects are not supported"
  )
})

test_that("gseaResult mixed class inside a named list gets GSEA error", {
  mock <- structure(list(), class = c("gseaResult", "enrichResult"))
  expect_error(
    normalize_input(list(A = mock)),
    "GSEA result objects are not supported"
  )
})

test_that("enrichResult without gseaResult tag works normally", {
  mock <- structure(list(Description = "t1", ID = "GO:01", pvalue = 0.01,
                         p.adjust = 0.05, geneID = "A/B", Count = 5L,
                         GeneRatio = "5/100", BgRatio = "10/500",
                         qvalue = 0.05),
                    class = "enrichResult")
  result <- normalize_input(mock)
  expect_s3_class(result, "data.frame")
  expect_equal(nrow(result), 1L)
})
