/* === scReportEnrichment v0.1.0: Core JS ===================================== */

var SR = (function() {
  'use strict';

  var model = null;

  /* ---- Initialisation ---- */
  function init() {
    var el = document.getElementById('sr-payload');
    if (!el) { console.error('[scReportEnrichment] Payload element not found.'); return; }
    try {
      model = JSON.parse(el.textContent);
    } catch (e) {
      console.error('[scReportEnrichment] Failed to parse payload:', e);
      return;
    }

    wireSidebarEvents();
    renderOverview();
    renderMethodInfo();
    populateFilters();

    sr_renderDotPlot();
    sr_renderBarPlot();
    sr_initTermTable();
    sr_populateTermSelect();
  }

  /* ---- Sidebar: event delegation ---- */
  function wireSidebarEvents() {
    var sidebar = document.getElementById('sr-sidebar');
    if (!sidebar) return;
    sidebar.addEventListener('click', function(e) {
      var item = e.target.closest('.sidebar-item');
      if (!item) return;
      var section = item.getAttribute('data-section');
      if (section) showSection(section);
    });
  }

  /* ---- Navigation ---- */
  function showSection(name) {
    document.querySelectorAll('.section').forEach(function(s) {
      s.classList.remove('active');
    });
    document.querySelectorAll('.sidebar-item').forEach(function(item) {
      item.classList.remove('active');
    });

    var sec = document.getElementById('sec-' + name);
    if (sec) sec.classList.add('active');

    var nav = document.querySelector('.sidebar-item[data-section="' + name + '"]');
    if (nav) nav.classList.add('active');

    if (name === 'plots') {
      setTimeout(function() {
        sr_renderDotPlot();
        sr_renderBarPlot();
      }, 100);
    }
  }

  /* ---- Overview ---- */
  function renderOverview() {
    if (!model || !model.overview) return;

    var ov = model.overview;
    var cards = [
      { label: 'Comparisons',  value: ov.n_comparisons,  sub: '' },
      { label: 'Databases',    value: ov.n_databases,    sub: ov.databases ? ov.databases.join(', ') : '' },
      { label: 'Total Terms',  value: ov.n_total_terms,  sub: '' },
      { label: 'Significant',  value: ov.n_significant,  sub: 'p.adjust < ' + ov.p_adjust_cutoff },
      { label: 'Input Genes',  value: ov.input_gene_count !== undefined && ov.input_gene_count !== null ? ov.input_gene_count : 'N/A', sub: '' },
      { label: 'Mapped Genes', value: ov.mapped_gene_count !== undefined && ov.mapped_gene_count !== null ? ov.mapped_gene_count : 'N/A',
        sub: ov.mapping_rate !== undefined && ov.mapping_rate !== null ? (ov.mapping_rate * 100).toFixed(1) + '% mapped' : '' }
    ];

    var container = document.getElementById('overview-cards');
    if (!container) return;
    container.innerHTML = cards.map(function(c) {
      return '<div class="card">' +
        '<div class="card-label">' + escHtml(c.label) + '</div>' +
        '<div class="card-value">' + escHtml(String(c.value)) + '</div>' +
        (c.sub ? '<div class="card-sub">' + escHtml(c.sub) + '</div>' : '') +
        '</div>';
    }).join('');

    var dbBreakdown = document.getElementById('database-breakdown');
    if (dbBreakdown && ov.database_counts) {
      dbBreakdown.innerHTML = Object.keys(ov.database_counts).map(function(db) {
        return '<span style="margin-right:12px;">' + escHtml(db) + ': <strong>' + ov.database_counts[db] + '</strong></span>';
      }).join('');
    }

    renderWarnings();
  }

  function renderWarnings() {
    var box = document.getElementById('warnings-box');
    var list = document.getElementById('warnings-list');
    if (!box || !list || !model.warnings || model.warnings.length === 0) return;
    box.style.display = 'block';
    list.innerHTML = model.warnings.map(function(w) {
      return '<div class="warning-item">' + escHtml(w) + '</div>';
    }).join('');
  }

  /* ---- Method Info ---- */
  function renderMethodInfo() {
    if (!model || !model.metadata) return;
    var table = document.getElementById('method-table');
    if (!table) return;

    var rows = [
      ['Analysis Type',     model.metadata.analysis_type],
      ['Species',           model.metadata.species],
      ['Reference Species', model.metadata.reference_species],
      ['Gene ID Type',      model.metadata.gene_id_type],
      ['Analysis Tool',     model.metadata.analysis_tool],
      ['Tool Version',      model.metadata.analysis_tool_version],
      ['Database',          model.metadata.database],
      ['Database Version',  model.metadata.database_version],
      ['Ontology',          model.metadata.ontology],
      ['p.adjust Method',   model.metadata.p_adjust_method],
      ['p.adjust Cutoff',   model.metadata.p_adjust_cutoff],
      ['Background Size',   model.metadata.background_size],
      ['Input Gene Count',  model.metadata.input_gene_count],
      ['Mapped Gene Count', model.metadata.mapped_gene_count],
      ['Mapping Rate',      model.metadata.mapping_rate !== undefined && model.metadata.mapping_rate !== null ?
                            (Number(model.metadata.mapping_rate) * 100).toFixed(1) + '%' : 'Not provided'],
      ['Ortholog Method',   model.metadata.ortholog_method],
      ['Generated At',      model.metadata.generated_at],
      ['Notes',             model.metadata.notes]
    ];

    table.innerHTML = rows.map(function(r) {
      return '<tr><td>' + escHtml(String(r[0])) + '</td><td>' + escHtml(String(r[1])) + '</td></tr>';
    }).join('');
  }

  /* ---- Filter Population ---- */
  function populateFilters() {
    if (!model) return;

    var selects = {
      'plot-comparison-filter':   model.comparisons,
      'plot-database-filter':     model.databases,
      'plot-ontology-filter':     model.ontologies,
      'plot-direction-filter':    model.directions,
      'table-comparison-filter':  model.comparisons,
      'table-database-filter':    model.databases,
      'table-ontology-filter':    model.ontologies,
      'table-direction-filter':   model.directions
    };

    Object.keys(selects).forEach(function(id) {
      var sel = document.getElementById(id);
      if (!sel) return;
      var values = selects[id] || [];
      while (sel.options.length > 1) sel.remove(1);
      values.forEach(function(v) {
        if (v === null || v === undefined) return;
        var opt = document.createElement('option');
        opt.value = v;
        opt.textContent = v;
        sel.appendChild(opt);
      });
    });
  }

  /* ---- Empty state ---- */
  function showEmpty(containerId) {
    var el = document.getElementById(containerId);
    if (!el) return;
    el.innerHTML = '<div class="empty-state">' +
      '<div class="empty-state-text">No enrichment terms were available for the selected input.</div>' +
      '</div>';
  }

  /* ---- Utilities ---- */
  function escHtml(str) {
    if (str === null || str === undefined) return 'Not provided';
    return String(str).replace(/&/g, '&amp;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/"/g, '&quot;');
  }

  function truncateText(text, maxLen) {
    maxLen = maxLen || 50;
    if (!text) return '';
    if (text.length <= maxLen) return text;
    return text.substring(0, maxLen - 3) + '...';
  }

  function safeJson(v) {
    if (v === Infinity || v === -Infinity) return null;
    if (typeof v === 'number' && isNaN(v)) return null;
    return v;
  }

  /* ---- Public API ---- */
  return {
    init:         init,
    showSection:  showSection,
    getModel:     function() { return model; },
    showEmpty:    showEmpty,
    escHtml:      escHtml,
    truncateText: truncateText,
    safeJson:     safeJson
  };
})();

document.addEventListener('DOMContentLoaded', function() { SR.init(); });
