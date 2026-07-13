# scReportEnrichment: Dependencies --------------------------------------------
#
# Manages external JavaScript/CSS dependencies (Plotly).
# Provides either self-contained inline bundles or CDN references.
# Separated from render_report.R so dependency logic is testable in isolation.


# Default candidate paths for the Plotly JS bundle
default_plotly_candidates <- function() {
  c(
    system.file("htmlwidgets/lib/plotlyjs/plotly-latest.min.js", package = "plotly"),
    system.file("htmlwidgets/lib/plotly/plotly-latest.min.js", package = "plotly"),
    system.file("dist/plotly.min.js", package = "plotly")
  )
}


#' Find the Plotly JavaScript bundle path
#'
#' Searches the default candidate locations. Returns the first existing path
#' or an empty string if none are found.
#'
#' @param candidates Character vector of candidate file paths. If NULL,
#'   uses \code{default_plotly_candidates()}.
#' @return Character path to the Plotly JS file, or "" if not found.
#' @keywords internal
find_plotly_bundle <- function(candidates = NULL) {
  if (is.null(candidates)) {
    candidates <- default_plotly_candidates()
  }

  for (path in candidates) {
    if (nzchar(path) && file.exists(path)) {
      return(path)
    }
  }
  ""
}


#' Resolve Plotly dependency for the HTML report
#'
#' In self-contained mode: finds the local Plotly JS bundle and returns
#' a complete `<script>` tag with the content inline. Errors if the bundle
#' is not found.
#'
#' In non-self-contained mode: returns a CDN `<script>` tag.
#'
#' @param self_contained Logical.
#' @param bundle_path Character. Optional explicit path to Plotly JS bundle.
#'   If NULL (default), searches default locations. Pass "" to force the
#'   missing-bundle error path (for testing).
#' @return A character string: either a `<script>` tag with inline JS,
#'   or a `<script src="...">` tag.
#' @keywords internal
build_plotly_dependency <- function(self_contained = TRUE, bundle_path = NULL) {
  if (!self_contained) {
    return('<script src="https://cdn.plot.ly/plotly-latest.min.js"></script>')
  }

  # Check plotly package availability
  if (!requireNamespace("plotly", quietly = TRUE)) {
    stop(
      "Unable to create a self-contained report. ",
      "The 'plotly' R package is required for self-contained mode.\n",
      "Install it with: install.packages('plotly')\n",
      "Or use self_contained = FALSE."
    )
  }

  if (is.null(bundle_path)) {
    bundle_path <- find_plotly_bundle()
  }

  if (!nzchar(bundle_path) || !file.exists(bundle_path)) {
    stop(
      "Unable to create a self-contained report because the local Plotly ",
      "JavaScript bundle was not found.\n",
      "Reinstall the 'plotly' package or use self_contained = FALSE."
    )
  }

  js <- paste(readLines(bundle_path, warn = FALSE), collapse = "\n")
  paste0("<script>", js, "</script>")
}


#' Build the report CSS tag
#'
#' Reads the package CSS and returns it wrapped in a `<style>` tag.
#'
#' @param css_path Path to the report.css file.
#' @return A `<style>` tag string.
#' @keywords internal
build_css_dependency <- function(css_path) {
  if (!file.exists(css_path)) {
    stop("CSS file not found: ", css_path)
  }
  css <- paste(readLines(css_path, warn = FALSE), collapse = "\n")
  paste0("<style>", css, "</style>")
}


#' Build a JavaScript dependency tag
#'
#' Reads a JS file and returns it wrapped in a `<script>` tag.
#'
#' @param js_path Path to the JS file.
#' @return A `<script>` tag with inline content.
#' @keywords internal
build_js_dependency <- function(js_path) {
  if (!file.exists(js_path)) {
    stop("JavaScript file not found: ", js_path)
  }
  js <- paste(readLines(js_path, warn = FALSE), collapse = "\n")
  paste0("<script>", js, "</script>")
}
