# scReportEnrichment: Term Table Data ------------------------------------------
#
# Prepares the enrichment term table for front-end rendering.
# Handles serialisation of list-columns (genes) for JSON output.


#' Prepare term table data for the report
#'
#' Converts the internal enrichment table to a display-friendly format,
#' serialising list-columns (genes) as semicolon-delimited strings.
#'
#' @param df Normalised enrichment data.frame.
#' @param p_adjust_cutoff Significance cutoff for marking significant rows.
#' @return A data.frame ready for JSON serialisation and front-end rendering.
#' @keywords internal
prepare_term_table <- function(df, p_adjust_cutoff = 0.05) {
  out <- df[, c("result_id", "comparison", "database", "ontology",
                "term_id", "term_name",
                "p_value", "p_adjust", "q_value",
                "gene_ratio", "background_ratio",
                "gene_count", "input_direction")]

  # Serialise gene lists
  out[["genes"]] <- vapply(df[["genes"]], function(g) {
    if (length(g) == 0L) return("")
    paste(g, collapse = "; ")
  }, character(1))

  # Round numeric columns for display
  out[["p_value"]]    <- signif(out[["p_value"]], 4)
  out[["p_adjust"]]   <- signif(out[["p_adjust"]], 4)
  if ("q_value" %in% names(out)) {
    out[["q_value"]] <- signif(out[["q_value"]], 4)
  }

  # Replace NA with null-safe values for JSON
  # (handled in JS; here we keep NAs, jsonlite will convert to null)

  # Add significance flag
  out[["significant"]] <- !is.na(df[["p_adjust"]]) & df[["p_adjust"]] < p_adjust_cutoff

  out
}
