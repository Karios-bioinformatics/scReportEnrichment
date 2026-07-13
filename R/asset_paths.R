# scReportEnrichment: Asset Paths ----------------------------------------------
#
# Centralised path resolution for all inst/ resources.
# Templates, CSS, JS, and schema are located relative to the installed package.


#' Resolve an asset path within the installed package
#'
#' @param ... Character path components relative to inst/.
#' @return An absolute file path.
#' @keywords internal
asset_path <- function(...) {
  system.file(..., package = "scReportEnrichment", mustWork = FALSE)
}

#' @rdname asset_path
#' @keywords internal
template_path <- function(name) {
  asset_path("templates", name)
}

#' @rdname asset_path
#' @keywords internal
partial_path <- function(name) {
  asset_path("templates", "partials", name)
}

#' @rdname asset_path
#' @keywords internal
css_path <- function(name) {
  asset_path("assets", "css", name)
}

#' @rdname asset_path
#' @keywords internal
js_path <- function(name) {
  asset_path("assets", "js", name)
}

#' @rdname asset_path
#' @keywords internal
schema_path <- function(name) {
  asset_path("schema", name)
}

# ---- Development-mode path resolution ----------------------------------------

#' Resolve asset paths during development (before package installation)
#'
#' Falls back to inst/ relative to the package root when system.file
#' returns an empty string (i.e. package not installed).
#'
#' @param type One of "templates", "partials", "css", "js", "schema".
#' @param name File name.
#' @return Character path.
#' @keywords internal
dev_asset_path <- function(type, name) {
  pkg_path <- asset_path(type, name)
  if (nzchar(pkg_path)) return(pkg_path)

  # Fallback: look relative to this source file's location
  # Assumes source is in R/ and assets are in inst/
  src_dir <- dirname(sys.frame(1)$ofile)
  if (is.null(src_dir) || !nzchar(src_dir)) {
    src_dir <- getwd()
  }
  pkg_root <- dirname(src_dir)
  file.path(pkg_root, "inst", type, name)
}
