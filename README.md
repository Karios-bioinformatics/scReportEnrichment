# scReportEnrichment

<p align="center">
  <strong>Functional enrichment reporting module for the scReport ecosystem.</strong>
</p>

<p align="center">
  <img src="https://img.shields.io/badge/Version-v0.0.0--alpha-blue" alt="Version">
  <img src="https://img.shields.io/badge/Status-Planned-lightgrey" alt="Status">
  <img src="https://img.shields.io/badge/Layer-scReport%20Module-lightgrey" alt="Layer">
  <img src="https://img.shields.io/badge/Focus-Functional%20Enrichment-purple" alt="Focus">
  <img src="https://img.shields.io/badge/License-MIT%20planned-yellow" alt="License">
</p>

## Overview

**scReportEnrichment** is a planned module in the **scReport** ecosystem for generating interactive HTML reports from functional enrichment analysis results.

It is intended to organize enrichment outputs from resources such as **GO**, **KEGG**, **Reactome**, **Hallmark gene sets**, and related pathway databases into a readable, navigable, and shareable report.

> Differential expression gives gene lists.  
> Functional enrichment explains what those gene lists may represent.  
> scReportEnrichment turns those results into an interactive report.

## Current Status

This repository is currently an early scaffold.

- No stable R API has been released yet.
- No analysis engine is implemented yet.
- The README defines the intended project boundary and development direction.

The first implementation will focus on **reporting pre-computed enrichment results**, rather than running every enrichment method internally.

## Position in the scReport Ecosystem

`scReportEnrichment` is designed as a downstream reporting module after differential expression analysis.

A typical workflow is expected to be:

```text
Single-cell object
  → QC / Feature / PCA / UMAP report        [scReportLite]
  → Cell composition report                 [scReportComposition]
  → Differential expression report          [scReportDE]
  → Functional enrichment report            [scReportEnrichment]
```

The package should not replace upstream analysis tools. Its role is to make enrichment results easier to inspect, compare, export, and communicate.

## Planned Report Sections

| Section | Planned Content |
|---------|-----------------|
| Overview | Summary cards for comparisons, databases, significant terms, and gene-set counts |
| Enrichment Dot Plot | Interactive term-level dot plot, usually showing significance, gene ratio, and count |
| Enrichment Bar Plot | Top enriched terms ranked by adjusted p-value, gene count, or enrichment score |
| Term Table | Searchable and sortable enrichment table with full statistics |
| Gene Set Detail | Selected term view with associated genes and metadata |
| Comparison View | Compare enrichment results across cell types, clusters, conditions, or contrasts |
| Method Info | Input source, database, cutoff settings, and report-generation metadata |

## Planned Input

The first target input will be a pre-computed enrichment result table.

Expected columns may include:

| Concept | Possible Column Names |
|---------|----------------------|
| Term ID | `ID`, `term_id`, `pathway_id` |
| Term name | `Description`, `term`, `term_name`, `pathway` |
| Database / source | `source`, `database`, `ontology`, `category` |
| P-value | `pvalue`, `p_value`, `p.val` |
| Adjusted P-value | `p.adjust`, `p_adj`, `padj`, `qvalue` |
| Gene ratio | `GeneRatio`, `gene_ratio`, `ratio` |
| Background ratio | `BgRatio`, `background_ratio` |
| Gene count | `Count`, `gene_count`, `n_genes` |
| Gene list | `geneID`, `genes`, `gene_list` |
| Group / contrast | `cluster`, `celltype`, `condition`, `comparison`, `contrast` |
| Direction | `direction`, `regulation`, `up_down` |

The package should support common enrichment output styles, especially table-like results produced by tools such as `clusterProfiler`.

## Planned API

The tentative main API is:

```r
build_screport_enrichment(
  enrichment_df,
  group_col      = NULL,
  term_col       = NULL,
  p_adjust_col   = NULL,
  gene_col       = NULL,
  database_col   = NULL,
  direction_col  = NULL,
  top_n          = 20,
  output_file    = "scReport_Enrichment.html",
  title          = "Functional Enrichment Report"
)
```

A later version may support multiple enrichment tables:

```r
build_screport_enrichment(
  enrichment_list = list(
    B_cell_up   = b_cell_up_go,
    B_cell_down = b_cell_down_go,
    T_cell_up   = t_cell_up_go
  ),
  output_file = "Enrichment_MultiGroup.html"
)
```

## Planned Visualisations

- GO / KEGG / Reactome / Hallmark enrichment dot plot
- Enrichment bar plot
- Term significance table
- Gene ratio versus adjusted p-value scatter plot
- Cell type / condition / comparison enrichment overview
- Gene-set detail panel
- Optional GSEA-style result summary in later versions

## Out of Scope

The initial version should avoid scope creep.

- No differential expression computation — this belongs to `scReportDE`
- No QC, PCA, UMAP, or marker exploration — these belong to `scReportLite`
- No cell composition analysis — this belongs to `scReportComposition`
- No automatic biological conclusion generation
- No claim that enrichment results prove mechanism
- No replacement for enrichment engines such as `clusterProfiler`, `fgsea`, `gprofiler2`, or Enrichr

## Design Principles

- **Report after analysis**: accept existing enrichment results first.
- **Table-driven**: standardize enrichment tables before plotting.
- **Interactive HTML**: produce a browsable report with Plotly/DT-style interaction.
- **Comparison-friendly**: make it easy to compare cell types, clusters, conditions, and contrasts.
- **No over-interpretation**: show results clearly, but do not invent biological claims.
- **scReport visual consistency**: follow the green-accent, card-based, left-navigation style used by other scReport modules.

## Development Roadmap

### v0.0.0-alpha

- Repository scaffold
- README and project boundary
- Planned API and input schema

### v0.1.0 planned

- Standardize enrichment result tables
- Generate enrichment overview cards
- Render dot plot, bar plot, and enrichment table
- Export a single HTML report
- Support one or multiple enrichment result tables

### Later versions

- GSEA result support
- Cross-database comparison
- Gene-set detail interaction
- Better support for multi-cell-type and multi-condition reports
- Integration with upstream `scReportDE` outputs

## Repository Structure

Planned structure:

```text
scReportEnrichment/
├── DESCRIPTION
├── NAMESPACE
├── LICENSE
├── README.md
├── R/
│   ├── enrich_normalize.R       # normalize enrichment result tables
│   ├── enrich_plots.R           # dot plot, bar plot, scatter plot
│   ├── enrich_html.R            # HTML layout, cards, sections
│   └── build_screport_enrich.R  # main report API
└── inst/
    └── test_enrichment_basic.R  # smoke tests
```

## Citation

No DOI has been released for this module yet.

After the first stable release, this section should be updated with the Zenodo DOI.

## License

MIT license planned. A `LICENSE` file should be added before the first formal release.
