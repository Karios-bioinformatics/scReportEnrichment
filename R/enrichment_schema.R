# scReportEnrichment: Internal ORA Schema ---------------------------------------
#
# Defines the canonical column names, types, and allowed values for the
# internal standardised enrichment result table and analysis metadata.
#
# This is the single source of truth that all other modules reference.
# Do NOT scatter column name strings across files.


# ---- Column definitions -------------------------------------------------------

ORA_REQUIRED_COLS <- c(
  "result_id", "comparison", "database", "term_id", "term_name",
  "p_value", "p_adjust", "gene_count", "genes"
)

ORA_ALL_COLS <- c(
  "result_id", "comparison", "database", "ontology",
  "term_id", "term_name",
  "p_value", "p_adjust", "q_value",
  "gene_ratio", "gene_ratio_num",
  "background_ratio", "background_ratio_num",
  "gene_count",
  "input_direction",
  "genes", "gene_ids_raw"
)

ORA_COL_TYPES <- list(
  result_id          = "character",
  comparison         = "character",
  database           = "character",
  ontology           = "character",
  term_id            = "character",
  term_name          = "character",
  p_value            = "numeric",
  p_adjust           = "numeric",
  q_value            = "numeric",
  gene_ratio         = "character",
  gene_ratio_num     = "numeric",
  background_ratio   = "character",
  background_ratio_num = "numeric",
  gene_count         = "integer",
  input_direction    = "character",
  genes              = "list",
  gene_ids_raw       = "character"
)

# ---- Allowed values -----------------------------------------------------------

VALID_DIRECTIONS <- c("up", "down", "mixed", "unspecified")

VALID_DATABASES <- c("GO", "KEGG", "Reactome", "Hallmark", "WikiPathway",
                     "custom", "other")

VALID_ONTOLOGIES <- c("BP", "CC", "MF", "ALL", NA_character_)


# ---- Metadata schema ----------------------------------------------------------

METADATA_FIELDS <- c(
  "analysis_type",
  "species",
  "reference_species",
  "gene_id_type",
  "analysis_tool",
  "analysis_tool_version",
  "database",
  "database_version",
  "ontology",
  "p_adjust_method",
  "p_adjust_cutoff",
  "background_size",
  "input_gene_count",
  "mapped_gene_count",
  "mapping_rate",
  "ortholog_method",
  "generated_at",
  "notes"
)

METADATA_DEFAULTS <- list(
  analysis_type       = "ORA",
  species             = NA_character_,
  reference_species   = NA_character_,
  gene_id_type        = NA_character_,
  analysis_tool       = NA_character_,
  analysis_tool_version = NA_character_,
  database            = NA_character_,
  database_version    = NA_character_,
  ontology            = NA_character_,
  p_adjust_method     = NA_character_,
  p_adjust_cutoff     = NA_real_,
  background_size     = NA_integer_,
  input_gene_count    = NA_integer_,
  mapped_gene_count   = NA_integer_,
  mapping_rate        = NA_real_,
  ortholog_method     = NA_character_,
  generated_at        = NA_character_,
  notes               = NA_character_
)


# ---- Mappable columns --------------------------------------------------------

# Only user-facing semantic columns can be mapped via column_map.
# Internal/derived fields (result_id, gene_ratio_num, etc.) are excluded.
ORA_MAPPABLE_COLS <- c(
  "comparison",
  "database",
  "ontology",
  "term_id",
  "term_name",
  "p_value",
  "p_adjust",
  "q_value",
  "gene_ratio",
  "background_ratio",
  "gene_count",
  "input_direction",
  "gene_ids_raw"
)

# ---- ClusterProfiler column mapping -------------------------------------------

CP_COLUMN_MAP <- c(
  ID          = "term_id",
  Description = "term_name",
  GeneRatio   = "gene_ratio",
  BgRatio     = "background_ratio",
  pvalue      = "p_value",
  p.adjust    = "p_adjust",
  qvalue      = "q_value",
  geneID      = "gene_ids_raw",
  Count       = "gene_count"
)

# Ontology extraction from clusterProfiler: first two letters of ID prefix
# (e.g. "GO:0006915" -> "GO", "KEGG:hsa04110" -> "KEGG")


# ---- Schema helpers -----------------------------------------------------------

#' Create an empty internal ORA table with correct column types
#'
#' @param n_rows Integer. Number of rows to initialise (default 0).
#' @return A data.frame with zero rows and all internal ORA columns.
#' @keywords internal
empty_ora_table <- function(n_rows = 0L) {
  template <- list(
    result_id          = character(n_rows),
    comparison         = character(n_rows),
    database           = character(n_rows),
    ontology           = character(n_rows),
    term_id            = character(n_rows),
    term_name          = character(n_rows),
    p_value            = numeric(n_rows),
    p_adjust           = numeric(n_rows),
    q_value            = numeric(n_rows),
    gene_ratio         = character(n_rows),
    gene_ratio_num     = numeric(n_rows),
    background_ratio   = character(n_rows),
    background_ratio_num = numeric(n_rows),
    gene_count         = integer(n_rows),
    input_direction    = character(n_rows),
    genes              = vector("list", n_rows),
    gene_ids_raw       = character(n_rows)
  )
  as.data.frame(template, stringsAsFactors = FALSE)
}


#' Create default metadata list
#'
#' Returns a named list populated with METADATA_DEFAULTS.
#' @return A named list with all metadata fields.
#' @keywords internal
default_metadata <- function() {
  METADATA_DEFAULTS
}
