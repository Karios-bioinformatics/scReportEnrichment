# scReportEnrichment: Term Detail Data -----------------------------------------
#
# Prepares per-term detail information for the Term Detail panel.
# Each term can be inspected individually; this creates the lookup structure.


#' Prepare term detail lookup
#'
#' Creates a named list keyed by result_id, where each entry contains
#' full term metadata for the detail panel.
#'
#' @param df Normalised enrichment data.frame.
#' @param metadata Validated metadata list.
#' @return A named list of term detail records.
#' @keywords internal
prepare_term_detail <- function(df, metadata) {
  if (nrow(df) == 0L) return(list())

  details <- lapply(seq_len(nrow(df)), function(i) {
    row <- df[i, , drop = FALSE]
    genes_vec <- row[["genes"]][[1]]
    list(
      result_id          = row[["result_id"]],
      term_id            = row[["term_id"]],
      term_name          = row[["term_name"]],
      database           = row[["database"]],
      ontology           = if (is.na(row[["ontology"]])) "Not provided" else row[["ontology"]],
      comparison         = row[["comparison"]],
      p_value            = signif(row[["p_value"]], 4),
      p_adjust           = signif(row[["p_adjust"]], 4),
      q_value            = if ("q_value" %in% names(row)) signif(row[["q_value"]], 4) else "Not provided",
      gene_ratio         = if (!is.na(row[["gene_ratio"]])) row[["gene_ratio"]] else "Not provided",
      background_ratio   = if ("background_ratio" %in% names(row) && !is.na(row[["background_ratio"]]))
                           row[["background_ratio"]] else "Not provided",
      gene_count         = row[["gene_count"]],
      input_direction    = row[["input_direction"]],
      genes              = as.list(genes_vec),
      n_genes            = length(genes_vec),
      species            = if (is.na(metadata[["species"]])) "Not provided" else metadata[["species"]],
      reference_species  = if (is.na(metadata[["reference_species"]])) "Not provided" else metadata[["reference_species"]],
      gene_id_type       = if (is.na(metadata[["gene_id_type"]])) "Not provided" else metadata[["gene_id_type"]],
      analysis_tool      = if (is.na(metadata[["analysis_tool"]])) "Not provided" else metadata[["analysis_tool"]],
      analysis_tool_version = if (is.na(metadata[["analysis_tool_version"]])) "Not provided" else metadata[["analysis_tool_version"]],
      p_adjust_method    = if (is.na(metadata[["p_adjust_method"]])) "Not provided" else metadata[["p_adjust_method"]]
    )
  })

  names(details) <- df[["result_id"]]
  details
}
