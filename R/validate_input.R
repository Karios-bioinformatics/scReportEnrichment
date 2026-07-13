# scReportEnrichment: Input Validation -----------------------------------------
#
# Validates the normalised enrichment table against the internal schema.
# All checks produce actionable error messages that tell the user:
#   - what is missing / wrong
#   - what the current state is
#   - how to fix it


#' Validate a normalized enrichment data.frame
#'
#' Checks required fields, types, value ranges, and edge cases.
#' Returns TRUE silently on success, stops with a descriptive error on failure.
#'
#' @param df A data.frame from normalize_input().
#' @param p_adjust_cutoff Numeric. Significance threshold for warnings.
#' @return Invisible TRUE, or character vector of warnings.
#' @keywords internal
validate_input <- function(df, p_adjust_cutoff = 0.05) {
  warnings <- character(0)

  # ---- 1. Required fields ----
  missing_req <- setdiff(ORA_REQUIRED_COLS, names(df))
  if (length(missing_req) > 0L) {
    stop(
      "Missing required columns: ", paste(missing_req, collapse = ", "), "\n",
      "Available columns: ", paste(names(df), collapse = ", "), "\n",
      "Use column_map to map your column names to the internal schema."
    )
  }

  # ---- 2. Type checks ----
  for (col in names(ORA_COL_TYPES)) {
    if (!col %in% names(df)) next

    expected_type <- ORA_COL_TYPES[[col]]
    actual <- df[[col]]

    if (col == "genes") {
      if (!is.list(actual)) {
        stop("Column 'genes' must be a list-column, got ", class(actual)[1])
      }
    } else if (expected_type == "character") {
      if (!is.character(actual)) {
        stop("Column '", col, "' must be character, got ", class(actual)[1])
      }
    } else if (expected_type == "numeric") {
      if (!is.numeric(actual)) {
        stop("Column '", col, "' must be numeric, got ", class(actual)[1])
      }
    } else if (expected_type == "integer") {
      if (!is.integer(actual) && !is.numeric(actual)) {
        stop("Column '", col, "' must be integer, got ", class(actual)[1])
      }
    }
  }

  # ---- 3. Value range checks ----

  # p_value: must be in [0, 1]
  pvals <- df[["p_value"]]
  if (any(!is.na(pvals) & (pvals < 0 | pvals > 1))) {
    stop("Column 'p_value' contains values outside [0, 1].")
  }

  # p_adjust: must be in [0, 1]
  padjs <- df[["p_adjust"]]
  if (any(!is.na(padjs) & (padjs < 0 | padjs > 1))) {
    stop("Column 'p_adjust' contains values outside [0, 1].")
  }

  # gene_count: must be non-negative
  gcounts <- df[["gene_count"]]
  if (any(!is.na(gcounts) & gcounts < 0)) {
    stop("Column 'gene_count' contains negative values.")
  }

  # gene_ratio_num: must be in [0, 1]
  gratio <- df[["gene_ratio_num"]]
  if (any(!is.na(gratio) & (gratio < 0 | gratio > 1))) {
    stop("Column 'gene_ratio_num' contains values outside [0, 1].")
  }

  # background_ratio_num: must be in [0, 1]
  bgratio <- df[["background_ratio_num"]]
  if (any(!is.na(bgratio) & (bgratio < 0 | bgratio > 1))) {
    stop("Column 'background_ratio_num' contains values outside [0, 1].")
  }

  # ---- 4. input_direction ----
  dirs <- df[["input_direction"]]
  invalid_dirs <- setdiff(unique(dirs[!is.na(dirs)]), VALID_DIRECTIONS)
  if (length(invalid_dirs) > 0L) {
    stop(
      "Invalid values in 'input_direction': ", paste(invalid_dirs, collapse = ", "), "\n",
      "Allowed: ", paste(VALID_DIRECTIONS, collapse = ", ")
    )
  }

  # ---- 5. result_id uniqueness ----
  rids <- df[["result_id"]]
  if (anyDuplicated(rids)) {
    stop("Column 'result_id' contains duplicate values. Each row must have a unique ID.")
  }

  # ---- 6. Warnings (non-fatal) ----

  # No significant terms
  sig_count <- sum(!is.na(padjs) & padjs < p_adjust_cutoff)
  if (sig_count == 0L) {
    warnings <- c(warnings,
      "No terms have p_adjust < ", as.character(p_adjust_cutoff),
      ". The report will display all available terms."
    )
  }

  # Missing direction
  if (all(df[["input_direction"]] == "unspecified" | is.na(df[["input_direction"]]))) {
    warnings <- c(warnings,
      "No input_direction specified. Direction-dependent features will be limited."
    )
  }

  # Empty comparison label
  empty_comp <- df[["comparison"]] == "" | is.na(df[["comparison"]])
  if (any(empty_comp)) {
    warnings <- c(warnings,
      "Some rows have empty or NA comparison labels."
    )
  }

  # Duplicate term IDs across comparisons (informational — allowed)
  dup_terms <- df[["term_id"]][duplicated(df[c("term_id", "comparison")])]
  if (length(dup_terms) > 0L) {
    warnings <- c(warnings,
      "Duplicate term_id within the same comparison detected. ",
      "This may indicate redundant rows."
    )
  }

  # GeneRatio parse failures
  if ("gene_ratio" %in% names(df) && any(!is.na(df[["gene_ratio"]]) &
      is.na(df[["gene_ratio_num"]]))) {
    warnings <- c(warnings,
      "Some GeneRatio values could not be parsed. Check the format (expected 'A/B' or numeric)."
    )
  }

  # p_adjust = 0
  if (any(!is.na(padjs) & padjs == 0)) {
    warnings <- c(warnings,
      "Some p_adjust values are exactly 0. These will be capped for ",
      "-log10 transformation in plots."
    )
  }

  # p_adjust = NA
  na_padj <- sum(is.na(padjs))
  if (na_padj > 0L) {
    warnings <- c(warnings,
      as.character(na_padj), " rows have NA p_adjust. These will be excluded ",
      "from significance filtering."
    )
  }

  warnings
}
