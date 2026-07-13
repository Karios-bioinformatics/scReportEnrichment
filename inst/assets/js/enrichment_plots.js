/* === scReportEnrichment v0.1.0: Enrichment Plots ================================ */
/* DOM, Plotly, and rendering logic. Pure helpers live in enrichment_plot_utils.js. */


/* ---- Plot rendering ---- */

function sr_getPlotFilters() {
  var f = {};
  var ids = {
    comparison: 'plot-comparison-filter',
    database:   'plot-database-filter',
    ontology:   'plot-ontology-filter',
    direction:  'plot-direction-filter'
  };
  for (var k in ids) {
    var el = document.getElementById(ids[k]);
    f[k] = el ? el.value : 'all';
  }
  return f;
}

function sr_getModelTopN() {
  var model = SR.getModel();
  return (model && model.top_n) ? model.top_n : 20;
}

function sr_renderDotPlot() {
  var model = SR.getModel();
  if (!model) return;
  var container = document.getElementById('dot-plot');
  if (!container) return;
  var data = model.dot_plot;
  if (!data || !data.term_name || data.term_name.length === 0) {
    SR.showEmpty('dot-plot');
    return;
  }

  var filters = sr_getPlotFilters();
  var filtered = SRPlotUtils.filterIndices(data, filters);
  filtered = SRPlotUtils.sortIndices(filtered, data, 'p_adjust');
  filtered = SRPlotUtils.takeTopN(filtered, sr_getModelTopN());

  if (filtered.length === 0) { SR.showEmpty('dot-plot'); return; }

  var trace = {
    x: filtered.map(function(i) { return SR.safeJson(data.gene_ratio_num[i]); }),
    y: filtered.map(function(i) { return data.term_name[i]; }),
    mode: 'markers',
    type: 'scatter',
    marker: {
      size: filtered.map(function(i) { return clamp(4, 20, (data.gene_count[i] || 0) * 0.5); }),
      color: filtered.map(function(i) { return SR.safeJson(data.neg_log10_padj[i]); }),
      colorscale: 'Greens', showscale: true,
      colorbar: { title: '-log10(p.adjust)' },
      line: { color: 'rgba(0,0,0,0.3)', width: 0.5 }
    },
    text: filtered.map(function(i) {
      return '<b>' + SR.escHtml(data.term_name[i]) + '</b><br>' +
        'Comparison: ' + SR.escHtml(data.comparison[i]) + '<br>' +
        'GeneRatio: ' + (data.gene_ratio_num[i] != null ? data.gene_ratio_num[i].toFixed(4) : 'N/A') + '<br>' +
        'Count: ' + (data.gene_count[i] || 0) + '<br>' +
        '-log10(p.adjust): ' + (data.neg_log10_padj[i] != null ? data.neg_log10_padj[i].toFixed(2) : 'N/A');
    }),
    hoverinfo: 'text'
  };

  Plotly.newPlot('dot-plot', [trace], {
    height: Math.max(400, filtered.length * 24),
    margin: { l: 260, r: 40, t: 10, b: 40 },
    xaxis: { title: 'Gene Ratio', zeroline: false },
    yaxis: { automargin: true, ticksuffix: '  ' },
    hovermode: 'closest'
  }, { displayModeBar: true, responsive: true });
}

function sr_renderBarPlot() {
  var model = SR.getModel();
  if (!model) return;
  var container = document.getElementById('bar-plot');
  if (!container) return;
  var data = model.bar_plot;
  if (!data || !data.term_name || data.term_name.length === 0) {
    SR.showEmpty('bar-plot');
    return;
  }

  var topNEl = document.getElementById('bar-top-n');
  var sortByEl = document.getElementById('bar-sort-by');
  var sortBy = sortByEl ? sortByEl.value : 'p_adjust';
  var topN = (topNEl && topNEl.value) ? parseInt(topNEl.value, 10) : sr_getModelTopN();
  if (isNaN(topN) || topN < 1) topN = sr_getModelTopN();

  var filters = sr_getPlotFilters();
  var filtered = SRPlotUtils.filterIndices(data, filters);
  // Sort by user-selected metric (uses compareNumeric: missing → end always)
  filtered = SRPlotUtils.sortIndices(filtered, data, sortBy);
  filtered = SRPlotUtils.takeTopN(filtered, topN);
  filtered.reverse();

  if (filtered.length === 0) { SR.showEmpty('bar-plot'); return; }

  var xVals, xTitle;
  if (sortBy === 'gene_count') {
    xVals = filtered.map(function(i) { return data.gene_count[i] || 0; });
    xTitle = 'Gene Count';
  } else if (sortBy === 'gene_ratio') {
    xVals = filtered.map(function(i) { return SR.safeJson(data.gene_ratio_num[i]) || 0; });
    xTitle = 'Gene Ratio';
  } else {
    xVals = filtered.map(function(i) { return SR.safeJson(data.neg_log10_padj[i]) || 0; });
    xTitle = '-log10(p.adjust)';
  }

  var trace = {
    x: xVals,
    y: filtered.map(function(i) { return SR.truncateText(data.term_name[i], 55); }),
    type: 'bar', orientation: 'h',
    marker: { color: xVals, colorscale: 'Greens', showscale: true, colorbar: { title: xTitle } },
    text: filtered.map(function(i) {
      return '<b>' + SR.escHtml(data.term_name[i]) + '</b><br>' +
        'Comparison: ' + SR.escHtml(data.comparison[i]) + '<br>' +
        'p.adjust: ' + (data.p_adjust[i] != null ? data.p_adjust[i].toExponential(2) : 'N/A') + '<br>' +
        'Count: ' + (data.gene_count[i] || 0);
    }),
    hoverinfo: 'text'
  };

  Plotly.newPlot('bar-plot', [trace], {
    height: Math.max(400, filtered.length * 24),
    margin: { l: 260, r: 40, t: 10, b: 40 },
    xaxis: { title: xTitle, zeroline: true },
    yaxis: { automargin: true, ticksuffix: '  ' },
    hovermode: 'closest'
  }, { displayModeBar: true, responsive: true });
}

function clamp(min, max, val) {
  return Math.max(min, Math.min(max, val));
}

/* ---- Initialisation: wire all event listeners ---- */
document.addEventListener('DOMContentLoaded', function() {
  setTimeout(function() {
    var plotFilters = ['plot-comparison-filter', 'plot-database-filter',
                       'plot-ontology-filter', 'plot-direction-filter'];
    plotFilters.forEach(function(id) {
      var el = document.getElementById(id);
      if (el) el.addEventListener('change', function() { sr_renderDotPlot(); sr_renderBarPlot(); });
    });

    var sortByEl = document.getElementById('bar-sort-by');
    if (sortByEl) sortByEl.addEventListener('change', sr_renderBarPlot);

    var topNEl = document.getElementById('bar-top-n');
    if (topNEl) {
      topNEl.value = sr_getModelTopN();
      topNEl.addEventListener('change', sr_renderBarPlot);
    }
  }, 200);
});
