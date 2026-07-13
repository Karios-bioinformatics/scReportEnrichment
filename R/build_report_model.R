# scReportEnrichment: Report Model Builder -------------------------------------
#
# Assembles all prepared data into a pure R list (the "report model").
# This list is the single data contract between R computation and HTML rendering.
# It must be fully testable without any file I/O or HTML generation.


#' Build the enrichment report model
#'
#' Assembles the normalised enrichment table, metadata, overview,
#' plot data, term table, and term details into a single structured list
#' suitable for serialisation and template rendering.
#'
#' @param df Normalised enrichment data.frame.
#' @param metadata Validated metadata list.
#' @param top_n Maximum terms to display in plots (applied by front-end).
#' @param p_adjust_cutoff Significance threshold.
#' @param title Report title.
#' @param generation_time Character timestamp.
#' @param package_version Character. scReportEnrichment version.
#' @param warnings Character vector of non-fatal warnings.
#' @return A named list (the report model).
#' @keywords internal
build_report_model <- function(
    df,
    metadata,
    top_n            = 20L,
    p_adjust_cutoff  = 0.05,
    title            = "Functional Enrichment Report",
    generation_time  = NULL,
    package_version  = NULL,
    warnings         = character(0)
) {
  if (is.null(generation_time)) {
    generation_time <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  }

  if (is.null(package_version)) {
    pkg_version <- tryCatch(
      as.character(utils::packageVersion("scReportEnrichment")),
      error = function(e) "0.1.0"
    )
  } else {
    pkg_version <- package_version
  }

  # ---- Prepare sections ----
  # Plot data: send ALL significant terms; front-end applies top_n per filter
  overview    <- prepare_overview(df, metadata, p_adjust_cutoff)
  dot_plot    <- prepare_dot_plot_data(df, p_adjust_cutoff)
  bar_plot    <- prepare_bar_plot_data(df, p_adjust_cutoff)
  term_table  <- prepare_term_table(df, p_adjust_cutoff)
  term_detail <- prepare_term_detail(df, metadata)

  # ---- Build filter lists ----
  comparisons <- unique(df[["comparison"]])
  databases   <- unique(df[["database"]])
  ontologies  <- unique(df[["ontology"]])
  directions  <- unique(df[["input_direction"]])

  # ---- Build model ----
  model <- list(
    title            = title,
    generation_time  = generation_time,
    package_version  = pkg_version,
    metadata         = lapply(metadata, function(x) if (is.na(x)) "Not provided" else x),
    overview         = overview,
    comparisons      = as.list(comparisons),
    databases        = as.list(databases),
    ontologies       = as.list(ontologies[!is.na(ontologies)]),
    directions       = as.list(directions),
    dot_plot         = dot_plot,
    bar_plot         = bar_plot,
    term_table       = term_table,
    term_details     = term_detail,
    top_n            = top_n,
    p_adjust_cutoff  = p_adjust_cutoff,
    warnings         = as.list(warnings),
    empty_result     = (nrow(df) == 0L)
  )

  class(model) <- c("scReportEnrichment_model", "list")
  model
}
