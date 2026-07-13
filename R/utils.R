# scReportEnrichment: Utilities ------------------------------------------------
#
# Small helper functions shared across modules. No domain logic here.


`%||%` <- function(x, y) {
  if (is.null(x)) y else x
}

`%|na|%` <- function(x, y) {
  if (length(x) == 0 || all(is.na(x))) y else x
}


# ---- Stable short hash (pure R, no external dependency) -----------------------

#' Generate a stable 6-char hex hash from a string
#'
#' Pure R implementation of a djb2-style hash with modulo-based
#' range restriction. Uses double-precision arithmetic to avoid integer
#' overflow. Always outputs exactly 6 lowercase hex characters.
#' Deterministic, session-independent, no external package dependency.
#'
#' @param x Character string. Must be length 1.
#' @return 6-character hex string. "000000" for NULL/NA/empty input.
#' @keywords internal
stable_hash6 <- function(x) {
  if (is.null(x) || length(x) != 1L || is.na(x) || !nzchar(x)) {
    return("000000")
  }

  modulus <- 16^6  # 16777216
  hash <- 5381

  bytes <- as.integer(charToRaw(enc2utf8(as.character(x))))

  for (b in bytes) {
    hash <- (hash * 33 + b) %% modulus
  }

  sprintf("%06x", as.integer(hash))
}


# ---- Unique ID generation ------------------------------------------------------

#' Generate globally-unique, comparison-scoped result IDs
#'
#' Produces IDs like \code{readable__HASH__ORA_0001}.
#' The comparison label is sanitised to a readable prefix; a stable hex hash
#' disambiguates source comparisons that sanitise to the same text (e.g.
#' "B cell" vs "B-cell"). Each candidate ID is checked against
#' \code{existing_ids}; collisions are resolved with deterministic suffixes.
#'
#' @param n Integer. Number of IDs to generate.
#' @param comparison Character. Original comparison label.
#' @param existing_ids Character vector of already-used IDs (for global
#'   uniqueness across multiple comparisons).
#' @param prefix Character. Default \code{"ORA"}.
#' @return Character vector of globally unique IDs.
#' @keywords internal
make_scoped_result_ids <- function(n, comparison, existing_ids = character(0),
                                   prefix = "ORA") {
  if (n == 0L) return(character(0))

  # Build a readable scope from the comparison label
  sanitised <- gsub("[^A-Za-z0-9_]", "_", comparison)
  sanitised <- gsub("_+", "_", sanitised)
  sanitised <- gsub("^_|_$", "", sanitised)
  # If sanitised to empty (all chinese etc.), use "group"
  if (!nzchar(sanitised)) sanitised <- "group"

  # Stable hash of the ORIGINAL comparison (pre-sanitise)
  hash <- stable_hash6(comparison)

  scope <- paste0(sanitised, "__", hash)

  # Generate candidate IDs
  candidates <- sprintf("%s__%s_%04d", scope, prefix, seq_len(n))

  # Resolve collisions against existing_ids one by one
  resolved <- character(n)
  for (i in seq_len(n)) {
    cand <- candidates[i]
    # If collision, append suffixes until unique
    suffix <- 0L
    while (cand %in% existing_ids || cand %in% resolved[seq_len(max(0, i - 1))]) {
      suffix <- suffix + 1L
      cand <- sprintf("%s__%s_%04d_c%d", scope, prefix, i, suffix)
    }
    resolved[i] <- cand
  }

  resolved
}

#' Generate simple sequential IDs (used where scoped IDs aren't needed)
#'
#' @param n Integer. Number of IDs.
#' @param prefix Character prefix.
#' @return Character vector.
#' @keywords internal
make_result_ids <- function(n, prefix = "ORA") {
  if (n == 0L) return(character(0))
  sprintf("%s_%04d", prefix, seq_len(n))
}


# ---- Gene string parsing ------------------------------------------------------

#' Parse a gene separator string into a character vector
#'
#' Supports "/", ";", "," separators. Trims whitespace.
#'
#' @param x Character string of gene identifiers.
#' @return Character vector of individual genes.
#' @keywords internal
parse_gene_string <- function(x) {
  if (is.null(x) || is.na(x) || !nzchar(x)) return(character(0))
  parts <- strsplit(as.character(x), "[/;,]")[[1]]
  parts <- trimws(parts)
  parts[parts != ""]
}


# ---- Ratio parsing ------------------------------------------------------------

#' Parse a GeneRatio / BgRatio string like "5/100" into numerator and denominator
#'
#' @param x Character string in "A/B" format, or numeric.
#' @return A numeric(2) vector c(numerator, denominator), or c(NA_real_, NA_real_).
#' @keywords internal
parse_ratio_string <- function(x) {
  if (is.null(x) || length(x) == 0) return(c(NA_real_, NA_real_))
  x <- as.character(x[1])
  if (is.na(x) || !nzchar(x)) return(c(NA_real_, NA_real_))
  if (!grepl("/", x)) {
    val <- suppressWarnings(as.numeric(x))
    return(c(val, NA_real_))
  }
  parts <- strsplit(x, "/")[[1]]
  num <- suppressWarnings(as.numeric(parts[1]))
  den <- suppressWarnings(as.numeric(parts[2]))
  c(num, den)
}


#' Compute ratio numeric value from a "A/B" string
#'
#' @param x Character string in "A/B" format.
#' @return Numeric ratio, or NA if unparseable.
#' @keywords internal
ratio_to_numeric <- function(x) {
  nd <- parse_ratio_string(x)
  if (is.na(nd[2]) || nd[2] == 0) {
    if (!is.na(nd[1])) return(nd[1])
    return(NA_real_)
  }
  nd[1] / nd[2]
}


# ---- Safe -log10 --------------------------------------------------------------

#' Safe -log10 transformation, handling zeros and NAs
#'
#' @param p Numeric vector of p-values.
#' @param replace_inf Value to replace Inf with. Default 320 (roughly
#'   -log10(.Machine$double.xmin) for safety).
#' @return Numeric vector of -log10(p).
#' @keywords internal
safe_neg_log10 <- function(p, replace_inf = 320) {
  p <- suppressWarnings(as.numeric(p))
  p[p <= 0] <- .Machine$double.xmin
  res <- -log10(p)
  res[is.infinite(res)] <- replace_inf
  res[is.na(p)] <- NA_real_
  res
}


# ---- Escape helpers -----------------------------------------------------------

#' HTML text escape
#'
#' Escapes <, >, &, " for safe insertion into HTML text content.
#'
#' @param x Character string.
#' @return Escaped string.
#' @keywords internal
escape_html_text <- function(x) {
  if (is.null(x) || is.na(x)) return("Not provided")
  x <- as.character(x)
  x <- gsub("&", "&amp;", x, fixed = TRUE)
  x <- gsub("<", "&lt;", x, fixed = TRUE)
  x <- gsub(">", "&gt;", x, fixed = TRUE)
  x <- gsub('"', "&quot;", x, fixed = TRUE)
  x
}

#' HTML attribute escape
#'
#' Like html_text but stricter: also escapes single quotes for use in
#' attribute values delimited by single quotes.
#'
#' @param x Character string.
#' @return Escaped string.
#' @keywords internal
escape_html_attribute <- function(x) {
  x <- escape_html_text(x)
  x <- gsub("'", "&#39;", x, fixed = TRUE)
  x
}

#' JSON-for-script-tag escape
#'
#' Escapes characters that would break \code{<script>} tag embedding:
#' \code{<}, \code{>}, \code{&} are converted to unicode escapes so
#' that \code{</script>} cannot appear in the JSON payload. Also handles
#' U+2028 (LINE SEPARATOR) and U+2029 (PARAGRAPH SEPARATOR).
#'
#' @param json_string A JSON string produced by jsonlite::toJSON().
#' @return Safe string for embedding in \code{<script type="application/json">}.
#' @keywords internal
escape_json_for_script <- function(json_string) {
  json_string <- gsub("<", "\\u003c", json_string, fixed = TRUE)
  json_string <- gsub(">", "\\u003e", json_string, fixed = TRUE)
  json_string <- gsub("&", "\\u0026", json_string, fixed = TRUE)
  json_string <- gsub("\u2028", "\\u2028", json_string, fixed = TRUE)
  json_string <- gsub("\u2029", "\\u2029", json_string, fixed = TRUE)
  json_string
}


# ---- Text occurrence counter --------------------------------------------------

#' Count exact (fixed) occurrences of a pattern in a string
#'
#' @param text Character string to search.
#' @param pattern Character pattern (fixed match).
#' @return Integer count.
#' @keywords internal
count_fixed <- function(text, pattern) {
  if (!nzchar(pattern)) return(0L)
  pos <- gregexpr(pattern, text, fixed = TRUE)[[1]]
  if (length(pos) == 1L && pos == -1L) return(0L)
  length(pos)
}


# ---- List to column helpers ---------------------------------------------------

#' Ensure a column exists in a data.frame, creating it with a default if absent
#'
#' @param df A data.frame.
#' @param col Character column name.
#' @param default Default value to fill if column is missing.
#' @return The modified data.frame.
#' @keywords internal
ensure_column <- function(df, col, default = NA_character_) {
  if (!col %in% names(df)) {
    df[[col]] <- rep(default, nrow(df))
  }
  df
}
