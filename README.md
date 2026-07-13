# scReportEnrichment

<p align="center">
  <strong>Functional enrichment reporting module for the scReport ecosystem.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-0.1.0-blue" alt="Version">
  <img src="https://img.shields.io/badge/Status-Verification%20Pending-yellow" alt="Status">
  <img src="https://img.shields.io/badge/Layer-scReport%20Module-lightgrey" alt="Layer">
  <img src="https://img.shields.io/badge/Focus-Functional%20Enrichment-purple" alt="Focus">
  <img src="https://img.shields.io/badge/License-MIT-green" alt="License">
</p>

## Overview

**scReportEnrichment** is an interactive HTML reporting package within the scReport ecosystem dedicated to functional enrichment analysis.

It accepts **pre-computed ORA (Over-Representation Analysis) enrichment results** and produces interactive, traceable, and shareable HTML reports.

> Differential expression gives gene lists.  
> Functional enrichment explains what those gene lists may represent.  
> scReportEnrichment turns those results into an interactive report.

### v0.1.0 Scope

scReportEnrichment v0.1.0 is a **reporting tool**, not an analysis tool:

- Accepts pre-computed ORA results (generic data.frames and clusterProfiler enrichResult objects).
- Does **not** run enrichment calculations.
- Does **not** perform differential expression.
- Does **not** accept Seurat objects.
- Does **not** support GSEA results (planned for a future version with an independent schema).
- Is **species-agnostic**: species support depends on upstream databases, ID mapping, and annotation quality.
- GSEA support is planned for a future version with an **independent schema**; do not pass `gseaResult` objects to v0.1.0.

### Development Status

The v0.1.0 implementation is complete and has passed static code review. The
front-end filter, sort, and top-N utilities are covered by JavaScript behavior
tests. Formal release verification is still pending because the following have
not yet been run in an R-enabled environment:

- `testthat` test suite
- `roxygen2::roxygenise()` and `man/` generation
- `R CMD build` and `R CMD check`
- Browser-level validation of the generated Plotly report

Accordingly, v0.1.0 should currently be treated as a development build rather
than a verified release.

## Position in the scReport Ecosystem

scReportEnrichment is designed as a downstream reporting module after differential expression analysis:

```
Single-cell object
  -> QC / Feature / PCA / UMAP report        [scReportLite]
  -> Cell composition report                 [scReportComposition]
  -> Differential expression report          [scReportDE]
  -> Functional enrichment report            [scReportEnrichment]
```

## Installation

```r
# From GitHub (after release)
# remotes::install_github("Karios-bioinformatics/scReportEnrichment")

# Local development
devtools::install("path/to/scReportEnrichment")
```

## Quick Start

### From a clusterProfiler enrichResult

```r
library(scReportEnrichment)
library(clusterProfiler)
library(org.Hs.eg.db)

genes <- c("BCL2", "BAX", "CASP3", "TP53", "ATG5", "ATG7", "BECN1")

ego <- enrichGO(
  gene   = genes,
  OrgDb  = org.Hs.eg.db,
  ont    = "BP",
  keyType = "SYMBOL"
)

build_screport_enrichment(
  ego,
  metadata = list(
    species       = "Homo sapiens",
    gene_id_type  = "SYMBOL",
    analysis_tool = "clusterProfiler"
  )
)
```

### From a generic data.frame

```r
my_results <- data.frame(
  term_id    = c("GO:0006915", "GO:0006914", "GO:0006950"),
  term_name  = c("apoptotic process", "autophagy", "response to stress"),
  p_value    = c(0.0001, 0.0005, 0.001),
  p_adjust   = c(0.001, 0.003, 0.005),
  gene_count = c(15, 12, 20),
  GeneRatio  = c("15/200", "12/200", "20/200"),
  geneID     = c("BCL2/BAX/CASP3", "ATG5/ATG7/BECN1", "HSPA1A/HSPA1B"),
  stringsAsFactors = FALSE
)

build_screport_enrichment(my_results)
```

### Using column_map for non-standard column names

```r
weird_df <- data.frame(
  pathway_id = "P1",
  pathway    = "Apoptosis",
  padj       = 0.001,
  n_genes    = 15,
  gene_list  = "BCL2/BAX/CASP3",
  stringsAsFactors = FALSE
)

build_screport_enrichment(
  weird_df,
  column_map = c(
    term_id    = "pathway_id",
    term_name  = "pathway",
    p_adjust   = "padj",
    gene_count = "n_genes",
    gene_ids_raw = "gene_list"
  )
)
```

### Multiple comparisons as a named list

```r
build_screport_enrichment(
  enrichment = list(
    B_cell_up   = b_cell_up_go,
    B_cell_down = b_cell_down_go,
    T_cell_up   = t_cell_up_go
  ),
  metadata = list(
    species        = "Homo sapiens",
    gene_id_type   = "SYMBOL",
    analysis_tool  = "clusterProfiler",
    analysis_tool_version = "4.10.0"
  ),
  output_file = "Enrichment_MultiGroup.html"
)
```

### Empty input

```r
# Empty input produces a valid HTML page (no errors)
empty_df <- data.frame(
  term_id   = character(0),
  term_name = character(0),
  p_value   = numeric(0),
  p_adjust  = numeric(0),
  gene_count = integer(0),
  genes     = character(0)
)

build_screport_enrichment(empty_df, output_file = "Empty_Report.html")
# Report displays: "No enrichment terms were available for the selected input."
```

## Input Types (v0.1.0)

| Input Type | Supported | Notes |
|------------|-----------|-------|
| Generic data.frame | Yes | Auto-detects common column names; use column_map for ambiguity |
| clusterProfiler enrichResult (ORA) | Yes | enrichGO, enrichKEGG, enricher |
| Named list of data.frames | Yes | Names become comparison labels |
| clusterProfiler gseaResult | **No** | Waits for future GSEA schema |
| Seurat object | No | Use scReportDE for DE first |
| Direct enrichment execution | No | Reporting only |

## Report Sections

| Section | Content |
|---------|---------|
| **Overview** | Summary cards: comparisons, databases, total/significant terms, gene counts |
| **Enrichment Dot Plot** | Interactive dot plot: gene ratio vs. term, sized by gene count, colored by -log10(p.adjust) |
| **Enrichment Bar Plot** | Top enriched terms ranked by p.adjust, gene count, or gene ratio |
| **Term Table** | Searchable and filterable enrichment table with full statistics |
| **Term Detail** | Per-term view with metadata, statistics, and complete gene list |
| **Method Info** | Analysis metadata, tool versions, cutoff values, and parameter settings |

## API

```r
build_screport_enrichment(
  enrichment,               # data.frame | enrichResult | named list
  metadata        = list(), # analysis-level metadata (all fields optional)
  column_map      = NULL,   # named vector for non-standard column names
  top_n           = 20,     # max terms in plots
  p_adjust_cutoff = 0.05,   # significance threshold
  output_file     = "scReport_Enrichment.html",
  title           = "Functional Enrichment Report",
  self_contained  = TRUE    # embed assets for offline use
)
```

## Metadata Fields

All metadata fields are optional. Missing fields display as "Not provided" in the report.

- `analysis_type` — v0.1.0 always uses `"ORA"`
- `species` — e.g. `"Homo sapiens"`
- `reference_species` — species used for ortholog mapping
- `gene_id_type` — e.g. `"SYMBOL"`, `"ENTREZID"`
- `analysis_tool` — e.g. `"clusterProfiler"`
- `analysis_tool_version` — e.g. `"4.10.0"`
- `database` — e.g. `"GO"`, `"KEGG"`
- `database_version` — e.g. `"2024-01-01"`
- `ontology` — e.g. `"BP"`, `"CC"`, `"MF"`
- `p_adjust_method` — e.g. `"BH"`
- `p_adjust_cutoff` — adjusted p-value threshold used for the report
- `background_size` — background gene-set size
- `input_gene_count` — number of input genes
- `mapped_gene_count` — number of successfully mapped genes
- `mapping_rate` — mapped/input ratio; computed when both counts are provided
- `ortholog_method` — method used for ortholog conversion
- `generated_at` — analysis or result-generation timestamp
- `notes` — free-text notes

## Internal ORA Schema

The package normalises all input to a standard internal schema with 17 columns:

| Column | Type | Description |
|--------|------|-------------|
| result_id | character | Package-generated internal key (e.g. `B_cell__a1b2c3__ORA_0001`) |
| comparison | character | Comparison/group label |
| database | character | Enrichment database source |
| ontology | character | Sub-ontology (BP/CC/MF/KEGG) |
| term_id | character | Database term ID |
| term_name | character | Term/pathway name |
| p_value | numeric | Raw p-value |
| p_adjust | numeric | Adjusted p-value |
| q_value | numeric | q-value / FDR |
| gene_ratio | character | Ratio string (e.g. "5/100") |
| gene_ratio_num | numeric | Parsed numeric ratio |
| background_ratio | character | Background ratio string |
| background_ratio_num | numeric | Parsed numeric background ratio |
| gene_count | integer | Overlap gene count |
| input_direction | character | up / down / mixed / unspecified |
| genes | list | List-column of gene identifiers |
| gene_ids_raw | character | Raw gene ID string |

Note: `input_direction` describes the direction of expression change in the **input data**. It does not claim pathway activation or inhibition.

`result_id` is always generated internally. An input column with the same name
is ignored, and `column_map` cannot map a source column to `result_id`. This
ensures that term-detail keys remain unique across multiple comparisons.

## Architecture

scReportEnrichment follows strict separation of concerns:

- **R/** — normalization, validation, report-model construction, dependency resolution, and rendering orchestration
- **inst/templates/** — HTML page template and partials
- **inst/assets/css/** — report stylesheet source
- **inst/assets/js/** — browser modules and DOM-independent plot utilities
- **inst/schema/** — JSON Schema for the internal ORA result format

CSS, JavaScript, and page-template source are maintained outside `R/`. The
renderer only reads and wraps those assets when assembling the final report.
Browser events use `addEventListener`; templates do not use inline `on*=` event
attributes.

### Self-Contained Mode

`self_contained = TRUE` embeds all JavaScript and CSS inline for offline use. It requires the `plotly` R package to be installed (for the Plotly JS bundle). If the bundle is not found, the function errors with a clear message rather than silently falling back to CDN.

`self_contained = FALSE` uses CDN for Plotly and requires internet access.

### Multi-Comparison top_n

The `top_n` parameter limits the number of terms displayed per filtered view,
not globally. Plot filters cover comparison, database, ontology, and input
direction. The dot plot ranks the filtered subset by adjusted p-value. The bar
plot can independently rank it by adjusted p-value, gene count, or gene ratio,
then applies its selected top-N value. Missing numeric values are placed after
valid values in both ascending and descending sorts.

## Dependencies

**Imports:** jsonlite, plotly

**Suggests:** clusterProfiler, testthat (>= 3.0.0)

## Out of Scope (v0.1.0)

- Running enrichment analysis (enrichGO, enrichKEGG, enricher, fgsea)
- GSEA result support (separate schema planned)
- Seurat object ingestion
- Differential expression
- Network-based enrichment visualization
- Automatic biological conclusion generation
- Species database support claims
- Database download or synchronization

## Development

```r
# Run tests
devtools::test()

# Build and check
devtools::build()
devtools::check()

# Install locally
devtools::install()
```

## Repository Structure

```
scReportEnrichment/
|-- DESCRIPTION
|-- NAMESPACE
|-- LICENSE
|-- README.md
|-- R/
|   |-- build_screport_enrichment.R    # Public API and orchestration
|   |-- normalize_input.R              # Generic/list input normalization
|   |-- normalize_clusterprofiler.R    # clusterProfiler ORA adapter
|   |-- validate_input.R               # Normalized result validation
|   |-- validate_metadata.R            # Analysis metadata validation
|   |-- enrichment_schema.R            # Canonical ORA schema
|   |-- prepare_*.R                    # Report-section data preparation
|   |-- build_report_model.R           # Report model assembly
|   |-- dependencies.R                 # Plotly/CSS/JS dependency handling
|   |-- render_report.R                # Template rendering
|   |-- asset_paths.R                  # Installed/development asset paths
|   `-- utils.R                        # Shared utilities and stable IDs
|-- inst/
|   |-- templates/
|   |   |-- report.html
|   |   `-- partials/
|   |-- assets/
|   |   |-- css/report.css
|   |   `-- js/
|   |       |-- report.js
|   |       |-- enrichment_plot_utils.js
|   |       |-- enrichment_plots.js
|   |       |-- term_table.js
|   |       `-- term_detail.js
|   `-- schema/ora-result.schema.json
`-- tests/
    |-- testthat.R
    |-- testthat/
    |   |-- fixtures/
    |   `-- test-*.R
    `-- js/test-sort-filter.js
```

The `man/` directory will be generated with `roxygen2::roxygenise()` during
formal R-package verification.

## Citation

No DOI has been released for this module yet. After the first stable release, this section will be updated with a Zenodo DOI.

## License

MIT License. See the LICENSE file for details.
