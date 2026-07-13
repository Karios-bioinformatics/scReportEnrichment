# scReportEnrichment: HTML Report Renderer ------------------------------------
#
# Reads HTML templates, CSS, and JavaScript from inst/ files, injects
# the report model as JSON payload, and writes the final self-contained
# (or non-self-contained) HTML report.
#
# No CSS, JavaScript, or HTML is defined inline in this file.


#' Render the enrichment report to an HTML file
#'
#' Reads all template partials, CSS, and JavaScript from inst/,
#' assembles them with the report model payload, and writes the output.
#'
#' @param model A report model list from \code{build_report_model()}.
#' @param output_file Path to the output HTML file.
#' @param self_contained Logical. If TRUE, embed all assets inline.
#' @return Invisibly, the path to the output file.
#' @keywords internal
render_report <- function(model, output_file, self_contained = TRUE) {
  # ---- Determine asset paths ----
  resolve_asset <- function(subpath) {
    pkg_path <- system.file(subpath, package = "scReportEnrichment", mustWork = FALSE)
    if (nzchar(pkg_path)) return(pkg_path)
    dev_base <- file.path(getwd(), "inst")
    dev_path <- file.path(dev_base, subpath)
    if (file.exists(dev_path)) return(dev_path)
    tryCatch({
      r_dir <- dirname(sys.frame(1)$ofile)
      file.path(dirname(r_dir), "inst", subpath)
    }, error = function(e) dev_path)
  }

  # ---- Load templates ----
  report_tpl      <- read_template(resolve_asset("templates/report.html"))
  sidebar_html    <- read_template(resolve_asset("templates/partials/sidebar.html"))
  overview_html   <- read_template(resolve_asset("templates/partials/overview.html"))
  plots_html      <- read_template(resolve_asset("templates/partials/plots.html"))
  term_table_html <- read_template(resolve_asset("templates/partials/term_table.html"))
  term_detail_html<- read_template(resolve_asset("templates/partials/term_detail.html"))
  method_html     <- read_template(resolve_asset("templates/partials/method_info.html"))

  # ---- Build dependencies ----
  css_tag      <- build_css_dependency(resolve_asset("assets/css/report.css"))
  plotly_tag   <- build_plotly_dependency(self_contained)

  # Read JS files (always inline)
  js_report      <- paste(readLines(resolve_asset("assets/js/report.js"), warn = FALSE), collapse = "\n")
  js_plot_utils  <- paste(readLines(resolve_asset("assets/js/enrichment_plot_utils.js"), warn = FALSE), collapse = "\n")
  js_plots       <- paste(readLines(resolve_asset("assets/js/enrichment_plots.js"), warn = FALSE), collapse = "\n")
  js_term_table  <- paste(readLines(resolve_asset("assets/js/term_table.js"), warn = FALSE), collapse = "\n")
  js_term_detail <- paste(readLines(resolve_asset("assets/js/term_detail.js"), warn = FALSE), collapse = "\n")

  # ---- Serialise report model (safe for script tag) ----
  report_payload <- jsonlite::toJSON(model, auto_unbox = TRUE, null = "null",
                                     na = "null", pretty = TRUE)
  report_payload <- escape_json_for_script(report_payload)

  # ---- Assemble HTML ----
  html <- report_tpl

  # Template variable substitution
  # HTML-context variables must be escape_html_text'd
  vars <- list(
    title            = escape_html_text(model[["title"]]),
    generation_time  = escape_html_text(model[["generation_time"]]),
    package_version  = escape_html_text(model[["package_version"]]),
    css_tag          = css_tag,
    plotly_tag       = plotly_tag,
    sidebar          = sidebar_html,
    overview         = overview_html,
    plots            = plots_html,
    term_table       = term_table_html,
    term_detail      = term_detail_html,
    method_info      = method_html,
    report_payload   = report_payload,
    js_report        = js_report,
    js_plot_utils    = js_plot_utils,
    js_enrichment_plots = js_plots,
    js_term_table    = js_term_table,
    js_term_detail   = js_term_detail
  )

  for (var_name in names(vars)) {
    placeholder <- paste0("{{", var_name, "}}")
    html <- gsub(placeholder, vars[[var_name]], html, fixed = TRUE)
  }

  # ---- Ensure output directory ----
  out_dir <- dirname(output_file)
  if (!nzchar(out_dir) || out_dir == ".") {
    out_dir <- getwd()
  }
  if (!dir.exists(out_dir)) {
    dir.create(out_dir, recursive = TRUE)
  }

  # ---- Write output ----
  writeLines(html, output_file)

  message("Report written to: ", normalizePath(output_file, mustWork = FALSE))

  invisible(output_file)
}


# ---- Template Reader ----

#' Read a template file as a single string
#'
#' @param path File path.
#' @return Character string of file contents.
#' @keywords internal
read_template <- function(path) {
  if (!file.exists(path)) {
    stop("Template file not found: ", path,
         "\nEnsure scReportEnrichment is installed or run from the package root.")
  }
  paste(readLines(path, warn = FALSE), collapse = "\n")
}
