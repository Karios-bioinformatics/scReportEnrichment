/* === scReportEnrichment v0.1.0: Plot Utils ====================================== */
/* Pure filter/sort/top_n helpers. No DOM dependencies. */
/* Loaded by enrichment_plots.js; testable via Node.js require().              */

(function(root) {
  'use strict';

  /**
   * Check whether a value is a finite number (not NaN, Infinity, null, or undefined).
   */
  function isFiniteNumber(value) {
    return typeof value === 'number' && Number.isFinite(value);
  }

  /**
   * Generic numeric comparator for sorting. Missing/non-finite values always
   * sort to the end, regardless of sort direction.
   *
   * @param a First value
   * @param b Second value
   * @param ascending true for ascending, false for descending
   * @returns negative if a < b, positive if a > b, 0 if equal
   */
  function compareNumeric(a, b, ascending) {
    var aMissing = !isFiniteNumber(a);
    var bMissing = !isFiniteNumber(b);

    if (aMissing && bMissing) return 0;
    if (aMissing) return 1;
    if (bMissing) return -1;

    return ascending ? a - b : b - a;
  }

  /**
   * Filter data indices by filter criteria.
   * Returns array of indices matching all active filters.
   */
  function filterIndices(data, filterIds) {
    if (!data || !data.term_name || data.term_name.length === 0) return [];

    var f = filterIds || {};
    var result = [];
    for (var i = 0; i < data.term_name.length; i++) {
      if (f.comparison && f.comparison !== 'all' && data.comparison[i] !== f.comparison) continue;
      if (f.database   && f.database   !== 'all' && data.database[i]   !== f.database)   continue;
      if (f.ontology   && f.ontology   !== 'all' && data.ontology[i]   !== f.ontology)   continue;
      if (f.direction  && f.direction  !== 'all' && data.input_direction[i] !== f.direction) continue;
      result.push(i);
    }
    return result;
  }

  /**
   * Sort indices by a named field.
   *
   * p_adjust: ascending (0 is best, missing → end)
   * gene_count: descending (missing → end)
   * gene_ratio: descending (missing → end)
   *
   * Does NOT mutate the input indices array.
   */
  function sortIndices(indices, data, sortBy) {
    var sorted = indices.slice();

    var ascending;
    if (sortBy === 'gene_count' || sortBy === 'gene_ratio') {
      ascending = false;
    } else {
      ascending = true;  // p_adjust
    }

    sorted.sort(function(a, b) {
      var col = (sortBy === 'gene_count')     ? data.gene_count :
                (sortBy === 'gene_ratio')     ? data.gene_ratio_num :
                                                data.p_adjust;
      return compareNumeric(col[a], col[b], ascending);
    });

    return sorted;
  }

  /**
   * Take at most topN elements.
   */
  function takeTopN(indices, topN) {
    if (typeof topN !== 'number' || topN < 1) topN = 20;
    return indices.slice(0, topN);
  }

  /* ---- Exports ---- */
  var exports = {
    isFiniteNumber: isFiniteNumber,
    compareNumeric: compareNumeric,
    filterIndices:  filterIndices,
    sortIndices:    sortIndices,
    takeTopN:       takeTopN
  };

  root.SRPlotUtils = exports;

  /* Node.js CommonJS support */
  if (typeof module !== 'undefined' && module.exports) {
    module.exports = exports;
  }

})(typeof globalThis !== 'undefined' ? globalThis : this);
