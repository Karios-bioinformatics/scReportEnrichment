# scReportEnrichment: Metadata Validation --------------------------------------
#
# Validates and normalises the analysis-level metadata list.
# All metadata fields are optional; missing fields are filled with defaults.


#' Validate and complete metadata list
#'
#' Takes a user-provided metadata list, validates known fields, fills
#' missing fields with METADATA_DEFAULTS, and returns a complete list.
#'
#' @param metadata A named list of metadata values.
#' @return A complete named list with all METADATA_FIELDS present.
#' @keywords internal
validate_metadata <- function(metadata) {
  if (!is.list(metadata)) {
    stop("metadata must be a named list, got ", class(metadata)[1])
  }

  out <- METADATA_DEFAULTS

  # Merge user-provided values
  for (field in names(metadata)) {
    if (!field %in% METADATA_FIELDS) {
      warning("Unknown metadata field '", field, "' will be ignored. ",
              "Known fields: ", paste(METADATA_FIELDS, collapse = ", "))
      next
    }
    out[[field]] <- metadata[[field]]
  }

  # ---- Value checks ----

  if (!is.na(out[["p_adjust_cutoff"]]) &&
      (out[["p_adjust_cutoff"]] <= 0 || out[["p_adjust_cutoff"]] > 1)) {
    warning("p_adjust_cutoff should be in (0, 1], got ", out[["p_adjust_cutoff"]])
  }

  if (!is.na(out[["mapping_rate"]]) &&
      (out[["mapping_rate"]] < 0 || out[["mapping_rate"]] > 1)) {
    warning("mapping_rate should be in [0, 1], got ", out[["mapping_rate"]])
  }

  if (!is.na(out[["mapped_gene_count"]]) && !is.na(out[["input_gene_count"]]) &&
      out[["input_gene_count"]] > 0) {
    computed_rate <- out[["mapped_gene_count"]] / out[["input_gene_count"]]
    if (is.na(out[["mapping_rate"]])) {
      out[["mapping_rate"]] <- computed_rate
    }
  }

  # ---- Warnings ----
  warnings <- character(0)

  if (is.na(out[["species"]])) {
    warnings <- c(warnings,
      "Species metadata not provided. Species-dependent features will be limited."
    )
  }

  if (is.na(out[["database_version"]])) {
    warnings <- c(warnings,
      "Database version not provided. Reproducibility may be affected."
    )
  }

  if (!is.na(out[["mapping_rate"]]) && out[["mapping_rate"]] < 0.5) {
    warnings <- c(warnings,
      "Mapping rate is below 50% (", round(out[["mapping_rate"]] * 100, 1),
      "%). Enrichment results may have limited coverage."
    )
  }

  # Set generated_at if not provided
  if (is.na(out[["generated_at"]])) {
    out[["generated_at"]] <- format(Sys.time(), "%Y-%m-%d %H:%M:%S %Z")
  }

  attr(out, "warnings") <- warnings
  out
}
