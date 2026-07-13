# scReportEnrichment: Overview Card Data ---------------------------------------
#
# Computes summary statistics for the Overview section cards.
# Pure data computation — no HTML generation.


#' Prepare overview summary statistics
#'
#' @param df Normalised enrichment data.frame.
#' @param metadata Validated metadata list.
#' @param p_adjust_cutoff Significance cutoff.
#' @return A named list of summary values.
#' @keywords internal
prepare_overview <- function(df, metadata, p_adjust_cutoff = 0.05) {
  n_comparisons <- length(unique(df[["comparison"]]))
  n_databases   <- length(unique(df[["database"]]))
  n_ontologies  <- length(setdiff(unique(df[["ontology"]]), NA_character_))
  n_total_terms <- nrow(df)
  n_significant <- sum(!is.na(df[["p_adjust"]]) & df[["p_adjust"]] < p_adjust_cutoff)

  # Database breakdown
  db_counts <- as.list(table(df[["database"]]))

  # Comparison breakdown
  comp_counts <- as.list(table(df[["comparison"]]))

  # Direction breakdown
  dir_counts <- as.list(table(df[["input_direction"]]))

  list(
    n_comparisons   = n_comparisons,
    n_databases     = n_databases,
    n_ontologies    = n_ontologies,
    n_total_terms   = n_total_terms,
    n_significant   = n_significant,
    p_adjust_cutoff = p_adjust_cutoff,
    databases       = names(db_counts),
    database_counts = db_counts,
    comparisons     = names(comp_counts),
    comparison_counts = comp_counts,
    direction_counts = dir_counts,
    input_gene_count    = metadata[["input_gene_count"]],
    mapped_gene_count   = metadata[["mapped_gene_count"]],
    mapping_rate        = metadata[["mapping_rate"]]
  )
}
