# scReportEnrichment: Main API — build_screport_enrichment() -------------------
#
# Single entry-point for the enrichment report generator.
# Accepts pre-computed ORA enrichment results and produces an interactive
# HTML report with overview cards, dot plot, bar plot, term table, and
# term detail panels.


#' Generate a Functional Enrichment HTML Report
#'
#' Takes pre-computed ORA (Over-Representation Analysis) enrichment results
#' and produces an interactive HTML report.
#'
#' This function does NOT perform enrichment analysis. It only reports
#' pre-computed results. GSEA result support is planned for a future version
#' with an independent schema.
#'
#' @param enrichment One of:
#'   \itemize{
#'     \item A \code{data.frame} of enrichment results.
#'     \item A clusterProfiler \code{enrichResult} object (ORA only).
#'     \item A named list of data.frames or enrichResult objects
#'           (names are used as comparison labels).
#'   }
#' @param metadata Optional named list of analysis-level metadata.
#'   See \code{METADATA_FIELDS} for available fields. All fields are
#'   optional; missing fields display as "Not provided".
#' @param column_map Optional named character vector mapping your column
#'   names to internal schema columns. Use when auto-detection is ambiguous.
#'   Example: \code{c(term_id = "pathway_id", p_adjust = "padj")}.
#' @param top_n Maximum number of terms to show in plots (applied per filter
#'   group on the front-end). Default: 20.
#' @param p_adjust_cutoff Significance threshold for adjusted p-values.
#'   Default: 0.05.
#' @param output_file Path to the output HTML file.
#'   Default: \code{"scReport_Enrichment.html"}.
#' @param title Report title shown in the header.
#'   Default: \code{"Functional Enrichment Report"}.
#' @param self_contained Logical. If TRUE, embed all assets inline for
#'   offline use (requires the plotly R package to be installed).
#'   If FALSE, uses CDN for Plotly. Default: TRUE.
#'
#' @return Invisibly, a list with elements:
#'   \item{enrichment}{The normalised enrichment data.frame}
#'   \item{output_file}{Normalised path to the generated HTML file}
#'   \item{model}{The full report model list}
#'   \item{metadata}{The validated metadata list}
#'   \item{warnings}{Character vector of non-fatal warnings}
#'
#' @export
#'
#' @examples
#' \dontrun{
#' library(scReportEnrichment)
#' library(clusterProfiler)
#'
#' # From a clusterProfiler enrichResult
#' ego <- enrichGO(gene = genes, OrgDb = org.Hs.eg.db, ont = "BP")
#' build_screport_enrichment(ego)
#'
#' # From a generic data.frame
#' my_results <- data.frame(
#'   term_id = c("GO:0006915", "GO:0006914"),
#'   term_name = c("apoptotic process", "autophagy"),
#'   p.adjust = c(0.001, 0.02),
#'   Count = c(15, 10),
#'   geneID = c("BCL2/BAX/CASP3", "ATG5/ATG7/BECN1"),
#'   GeneRatio = c("15/200", "10/200"),
#'   stringsAsFactors = FALSE
#' )
#' build_screport_enrichment(my_results)
#'
#' # Multiple comparisons as a named list
#' build_screport_enrichment(
#'   enrichment = list(
#'     B_cell_up   = b_cell_up_go,
#'     T_cell_up   = t_cell_up_go
#'   ),
#'   metadata = list(species = "Homo sapiens", gene_id_type = "SYMBOL")
#' )
#' }
build_screport_enrichment <- function(
    enrichment,
    metadata        = list(),
    column_map      = NULL,
    top_n           = 20L,
    p_adjust_cutoff = 0.05,
    output_file     = "scReport_Enrichment.html",
    title           = "Functional Enrichment Report",
    self_contained  = TRUE) {

  # ---- 0. Validate parameters ----
  validate_params(enrichment, metadata, column_map, top_n,
                  p_adjust_cutoff, output_file, title, self_contained)

  generation_time <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  all_warnings <- character(0)

  # ---- 1. Normalize input ----
  message("Step 1/5: Normalizing input...")
  df <- normalize_input(enrichment, column_map = column_map)

  if (nrow(df) == 0L) {
    all_warnings <- c(all_warnings,
      "Input contains zero enrichment results. An empty report will be generated."
    )
  }

  # ---- 2. Validate input ----
  message("Step 2/5: Validating input...")
  val_warnings <- validate_input(df, p_adjust_cutoff = p_adjust_cutoff)
  all_warnings <- c(all_warnings, val_warnings)

  # ---- 3. Validate metadata ----
  message("Step 3/5: Validating metadata...")
  meta <- validate_metadata(metadata)
  meta_warnings <- attr(meta, "warnings")
  if (length(meta_warnings) > 0) {
    all_warnings <- c(all_warnings, meta_warnings)
  }

  # ---- 4. Build report model ----
  message("Step 4/5: Building report model...")
  model <- build_report_model(
    df              = df,
    metadata        = meta,
    top_n           = top_n,
    p_adjust_cutoff = p_adjust_cutoff,
    title           = title,
    generation_time = generation_time,
    warnings        = all_warnings
  )

  # ---- 5. Render HTML ----
  message("Step 5/5: Rendering HTML report...")
  render_report(model, output_file, self_contained = self_contained)

  # ---- Console summary ----
  message("\n=== scReportEnrichment v0.1.0 ===")
  message("Comparisons: ", model[["overview"]][["n_comparisons"]])
  message("Total terms: ", model[["overview"]][["n_total_terms"]])
  message("Significant : ", model[["overview"]][["n_significant"]],
          " (p.adjust < ", p_adjust_cutoff, ")")
  if (length(all_warnings) > 0) {
    message("Warnings    : ", length(all_warnings))
  }
  message("Output      : ", normalizePath(output_file, mustWork = FALSE))
  if (!self_contained) {
    message("\n[!] Sharing notice: This report is NOT self-contained and requires internet access.")
    message("    To share offline, use self_contained = TRUE (requires the 'plotly' R package).")
  }

  invisible(list(
    enrichment = df,
    output_file = normalizePath(output_file, mustWork = FALSE),
    model       = model,
    metadata    = meta,
    warnings    = all_warnings
  ))
}


# ---- Parameter validation ----------------------------------------------------

validate_params <- function(enrichment, metadata, column_map,
                            top_n, p_adjust_cutoff, output_file,
                            title, self_contained) {
  # top_n
  if (length(top_n) != 1L || is.na(top_n) || !is.finite(top_n)) {
    stop("top_n must be a single finite integer >= 1")
  }
  top_n <- as.integer(top_n)
  if (top_n < 1L) stop("top_n must be >= 1")

  # p_adjust_cutoff
  if (length(p_adjust_cutoff) != 1L || !is.numeric(p_adjust_cutoff) ||
      is.na(p_adjust_cutoff) || !is.finite(p_adjust_cutoff)) {
    stop("p_adjust_cutoff must be a single finite numeric value")
  }
  if (p_adjust_cutoff <= 0 || p_adjust_cutoff > 1) {
    stop("p_adjust_cutoff must be in (0, 1]")
  }

  # output_file
  if (!is.character(output_file) || length(output_file) != 1L ||
      is.na(output_file) || !nzchar(output_file)) {
    stop("output_file must be a single non-empty character string")
  }
  if (!grepl("\\.html?$", output_file, ignore.case = TRUE)) {
    warning("output_file does not end with .html: ", output_file,
            ". The report may not open correctly in a browser.")
  }

  # title
  if (!is.character(title) || length(title) != 1L || is.na(title)) {
    stop("title must be a single non-NA character string")
  }

  # self_contained
  if (!is.logical(self_contained) || length(self_contained) != 1L ||
      is.na(self_contained)) {
    stop("self_contained must be a single non-NA logical value")
  }
}
