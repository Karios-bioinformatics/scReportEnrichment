# scReportEnrichment: Plot Data Preparation ------------------------------------
#
# Computes data.frames for enrichment dot plot and bar plot.
# Sends ALL significant terms (not globally-capped top_n) so that
# front-end filtering by comparison/database/direction sees correct data
# for every subgroup. Front-end applies top_n within the filtered set.
#
# Pure data computation — no Plotly or HTML generation here.


#' Prepare all significant dot plot data
#'
#' Returns ALL terms meeting the p_adjust cutoff. Front-end applies
#' top_n filtering per comparison/database/direction selection.
#'
#' @param df Normalised enrichment data.frame.
#' @param p_adjust_cutoff Significance cutoff.
#' @return A data.frame with columns for plotting.
#' @keywords internal
prepare_dot_plot_data <- function(df, p_adjust_cutoff = 0.05) {
  df_sig <- df[!is.na(df[["p_adjust"]]) & df[["p_adjust"]] < p_adjust_cutoff, , drop = FALSE]

  if (nrow(df_sig) == 0L) {
    return(data.frame(
      term_name       = character(0),
      comparison      = character(0),
      database        = character(0),
      ontology        = character(0),
      input_direction = character(0),
      gene_ratio_num  = numeric(0),
      gene_count      = integer(0),
      neg_log10_padj  = numeric(0),
      p_adjust        = numeric(0),
      term_id         = character(0),
      stringsAsFactors = FALSE
    ))
  }

  # Order by p_adjust ascending (front-end will re-sort as needed)
  df_sig <- df_sig[order(df_sig[["p_adjust"]]), , drop = FALSE]

  neg_log10 <- safe_neg_log10(df_sig[["p_adjust"]])

  data.frame(
    term_name       = df_sig[["term_name"]],
    comparison      = df_sig[["comparison"]],
    database        = df_sig[["database"]],
    ontology        = df_sig[["ontology"]],
    input_direction = df_sig[["input_direction"]],
    gene_ratio_num  = df_sig[["gene_ratio_num"]],
    gene_count      = df_sig[["gene_count"]],
    neg_log10_padj  = neg_log10,
    p_adjust        = df_sig[["p_adjust"]],
    term_id         = df_sig[["result_id"]],
    stringsAsFactors = FALSE
  )
}


#' Prepare all significant bar plot data
#'
#' Returns ALL terms meeting the p_adjust cutoff. Front-end applies
#' top_n filtering per comparison selection.
#'
#' @param df Normalised enrichment data.frame.
#' @param p_adjust_cutoff Significance cutoff.
#' @return A data.frame with columns for plotting.
#' @keywords internal
prepare_bar_plot_data <- function(df, p_adjust_cutoff = 0.05) {
  df_sig <- df[!is.na(df[["p_adjust"]]) & df[["p_adjust"]] < p_adjust_cutoff, , drop = FALSE]

  if (nrow(df_sig) == 0L) {
    return(data.frame(
      term_name       = character(0),
      comparison      = character(0),
      database        = character(0),
      ontology        = character(0),
      input_direction = character(0),
      p_adjust        = numeric(0),
      gene_count      = integer(0),
      gene_ratio_num  = numeric(0),
      neg_log10_padj  = numeric(0),
      term_id         = character(0),
      stringsAsFactors = FALSE
    ))
  }

  # Order by p_adjust ascending
  df_sig <- df_sig[order(df_sig[["p_adjust"]]), , drop = FALSE]

  neg_log10 <- safe_neg_log10(df_sig[["p_adjust"]])

  data.frame(
    term_name       = df_sig[["term_name"]],
    comparison      = df_sig[["comparison"]],
    database        = df_sig[["database"]],
    ontology        = df_sig[["ontology"]],
    input_direction = df_sig[["input_direction"]],
    p_adjust        = df_sig[["p_adjust"]],
    gene_count      = df_sig[["gene_count"]],
    gene_ratio_num  = df_sig[["gene_ratio_num"]],
    neg_log10_padj  = neg_log10,
    term_id         = df_sig[["result_id"]],
    stringsAsFactors = FALSE
  )
}
