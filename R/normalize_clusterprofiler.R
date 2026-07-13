# scReportEnrichment: Normalize clusterProfiler enrichResult --------------------
#
# Converts clusterProfiler ORA enrichResult objects into the internal
# standardised enrichment table defined in enrichment_schema.R.
#
# Handles enrichGO, enrichKEGG, and enricher outputs.
# Does NOT handle gseaResult — those are explicitly rejected upstream.


#' Normalize a clusterProfiler enrichResult to internal ORA schema
#'
#' Converts the enrichResult data.frame, maps known column names,
#' parses GeneRatio/BgRatio strings, extracts ontology, and fills
#' all internal schema columns.
#'
#' @param cp_result A clusterProfiler enrichResult object.
#' @param comparison Optional character. Comparison/group label for all rows.
#'   If NULL, defaults to "enrichment".
#' @return A data.frame conforming to the internal ORA schema.
#' @keywords internal
normalize_clusterprofiler <- function(cp_result, comparison = NULL) {
  # Convert to data.frame
  cp_df <- as.data.frame(cp_result)

  if (nrow(cp_df) == 0L) {
    return(empty_ora_table())
  }

  # Map known columns
  out <- data.frame(
    stringsAsFactors = FALSE
  )

  # Apply column mapping where columns exist in cp_df
  for (cp_col in names(CP_COLUMN_MAP)) {
    target_col <- CP_COLUMN_MAP[[cp_col]]
    if (cp_col %in% names(cp_df)) {
      out[[target_col]] <- as.character(cp_df[[cp_col]])
    }
  }

  # ---- Fill missing columns with defaults ----

  # result_id
  if (!"result_id" %in% names(out)) {
    out[["result_id"]] <- make_result_ids(nrow(out))
  }

  # comparison
  if (!"comparison" %in% names(out)) {
    out[["comparison"]] <- comparison %||% "enrichment"
  }

  # database — infer from result metadata or column availability
  if (!"database" %in% names(out)) {
    out[["database"]] <- detect_cp_database(cp_result, cp_df)
  }

  # ontology — for GO results, extract from ONTOLOGY slot or term_id prefix
  if (!"ontology" %in% names(out)) {
    out[["ontology"]] <- detect_cp_ontology(cp_result, out)
  }

  # p_value — from raw cp_df if not already mapped
  if (!"p_value" %in% names(out) && "pvalue" %in% names(cp_df)) {
    out[["p_value"]] <- as.numeric(cp_df[["pvalue"]])
  }
  if (!"p_value" %in% names(out)) {
    out[["p_value"]] <- rep(NA_real_, nrow(out))
  }

  # p_adjust
  if (!"p_adjust" %in% names(out) && "p.adjust" %in% names(cp_df)) {
    out[["p_adjust"]] <- as.numeric(cp_df[["p.adjust"]])
  }

  # q_value
  if (!"q_value" %in% names(out) && "qvalue" %in% names(cp_df)) {
    out[["q_value"]] <- as.numeric(cp_df[["qvalue"]])
  }

  # gene_count
  if (!"gene_count" %in% names(out) && "Count" %in% names(cp_df)) {
    out[["gene_count"]] <- as.integer(cp_df[["Count"]])
  }

  # gene_ids_raw
  if (!"gene_ids_raw" %in% names(out) && "geneID" %in% names(cp_df)) {
    out[["gene_ids_raw"]] <- as.character(cp_df[["geneID"]])
  }

  # ---- Parse ratios ----
  if ("gene_ratio" %in% names(out)) {
    out[["gene_ratio_num"]] <- vapply(out[["gene_ratio"]],
                                      ratio_to_numeric, numeric(1))
  } else {
    out[["gene_ratio"]] <- rep(NA_character_, nrow(out))
    out[["gene_ratio_num"]] <- rep(NA_real_, nrow(out))
  }

  if ("background_ratio" %in% names(out)) {
    out[["background_ratio_num"]] <- vapply(out[["background_ratio"]],
                                            ratio_to_numeric, numeric(1))
  } else {
    out[["background_ratio"]] <- rep(NA_character_, nrow(out))
    out[["background_ratio_num"]] <- rep(NA_real_, nrow(out))
  }

  # ---- Parse gene lists ----
  if ("gene_ids_raw" %in% names(out)) {
    out[["genes"]] <- lapply(out[["gene_ids_raw"]], parse_gene_string)
  } else {
    out[["genes"]] <- replicate(nrow(out), character(0), simplify = FALSE)
  }

  # ---- Fill remaining columns ----
  if (!"input_direction" %in% names(out)) {
    out[["input_direction"]] <- rep("unspecified", nrow(out))
  }

  # Ensure all internal columns present
  for (col in ORA_ALL_COLS) {
    if (!col %in% names(out)) {
      out[[col]] <- rep(NA_character_, nrow(out))
    }
  }

  # Enforce column order
  out <- out[, ORA_ALL_COLS, drop = FALSE]

  # Type coercion
  numeric_cols <- c("p_value", "p_adjust", "q_value",
                    "gene_ratio_num", "background_ratio_num")
  for (nc in numeric_cols) {
    out[[nc]] <- as.numeric(out[[nc]])
  }
  out[["gene_count"]] <- as.integer(out[["gene_count"]])
  out[["genes"]] <- lapply(out[["genes"]], as.character)

  out
}


# ---- Database detection -------------------------------------------------------

#' Detect database source from a clusterProfiler result
#'
#' @param cp_result enrichResult object.
#' @param cp_df data.frame form of cp_result.
#' @return Character database name.
#' @keywords internal
detect_cp_database <- function(cp_result, cp_df) {
  # Check for KEGG
  if (!is.null(cp_result@ontology) && cp_result@ontology == "KEGG") {
    return("KEGG")
  }
  # Check term_id pattern
  if ("ID" %in% names(cp_df) || "term_id" %in% names(cp_df)) {
    id_col <- if ("ID" %in% names(cp_df)) cp_df[["ID"]] else cp_df[["term_id"]]
    if (length(id_col) > 0) {
      first_id <- as.character(id_col[1])
      if (grepl("^K[0-9]{5}$", first_id)) return("KEGG")
      if (grepl("^GO:", first_id)) return("GO")
      if (grepl("^R-", first_id) || grepl("^REACTOME", first_id, ignore.case = TRUE)) {
        return("Reactome")
      }
      if (grepl("^WP", first_id)) return("WikiPathway")
      if (grepl("^HALLMARK", first_id, ignore.case = TRUE)) return("Hallmark")
    }
  }
  "custom"
}


#' Detect ontology from a clusterProfiler result
#'
#' @param cp_result enrichResult object.
#' @param out The partially-built internal data.frame.
#' @return Character vector of ontology values.
#' @keywords internal
detect_cp_ontology <- function(cp_result, out) {
  # enrichGO stores ontology in @ontology slot
  ont_slot <- tryCatch(cp_result@ontology, error = function(e) NULL)
  if (!is.null(ont_slot) && length(ont_slot) == 1L &&
      ont_slot %in% c("BP", "CC", "MF", "ALL")) {
    return(rep(ont_slot, nrow(out)))
  }

  # For KEGG results: "KEGG"
  if (!is.null(ont_slot) && ont_slot == "KEGG") {
    return(rep("KEGG", nrow(out)))
  }

  # Try to extract from database column
  db <- out[["database"]]
  if (length(db) > 0 && !is.na(db[1])) {
    if (db[1] %in% c("GO", "KEGG")) return(rep(db[1], nrow(out)))
  }

  # Infer from term_id prefix
  if ("term_id" %in% names(out) && nrow(out) > 0) {
    tid <- as.character(out[["term_id"]][1])
    if (grepl("^GO:", tid)) return(rep("ALL", nrow(out)))
    if (grepl("^K[0-9]{5}$", tid)) return(rep("KEGG", nrow(out)))
  }

  rep(NA_character_, nrow(out))
}
