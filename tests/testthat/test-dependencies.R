# Test: Dependencies — Plotly bundle, self-contained ===========================

context("Dependencies")

test_that("build_plotly_dependency self_contained=FALSE returns CDN tag", {
  tag <- build_plotly_dependency(self_contained = FALSE)
  expect_match(tag, "cdn.plot.ly")
  expect_match(tag, '<script src="https://')
})

test_that("build_plotly_dependency with nonexistent path errors", {
  skip_if_not_installed("plotly")
  expect_error(
    build_plotly_dependency(self_contained = TRUE, bundle_path = ""),
    "Unable to create a self-contained report"
  )
})

test_that("build_plotly_dependency with plotly installed returns inline script", {
  skip_if_not_installed("plotly")
  # Default behaviour (plotly is installed)
  tag <- build_plotly_dependency(self_contained = TRUE)
  expect_match(tag, "^<script>")
  expect_match(tag, "</script>$")
  expect_false(grepl("src=", tag))
})

test_that("find_plotly_bundle with empty candidates returns empty string", {
  result <- find_plotly_bundle(character(0))
  expect_equal(result, "")
})

test_that("find_plotly_bundle returns existing path", {
  result <- find_plotly_bundle(default_plotly_candidates())
  if (nzchar(result)) {
    expect_true(file.exists(result))
  }
})
