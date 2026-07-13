/* === scReportEnrichment: Term Table ========================================= */

var sr_termData = null;

function sr_initTermTable() {
  var model = SR.getModel();
  if (!model || !model.term_table) return;

  sr_termData = model.term_table;

  // Wire filters
  var filterIds = ['table-comparison-filter', 'table-database-filter',
                   'table-ontology-filter', 'table-direction-filter'];
  filterIds.forEach(function(id) {
    var el = document.getElementById(id);
    if (el) el.addEventListener('change', sr_renderTermTable);
  });

  var searchEl = document.getElementById('table-search');
  if (searchEl) searchEl.addEventListener('input', sr_renderTermTable);

  // Event delegation on table container for row clicks
  var container = document.getElementById('term-table-container');
  if (container) {
    container.addEventListener('click', function(e) {
      var row = e.target.closest('tr[data-result-id]');
      if (!row) return;
      var rid = row.getAttribute('data-result-id');
      if (rid) sr_showTermDetailById(rid);
    });
  }

  sr_renderTermTable();
}

function sr_renderTermTable() {
  if (!sr_termData) return;

  var data = sr_termData;
  var n = data.term_id ? data.term_id.length : 0;
  if (n === 0) {
    var c = document.getElementById('term-table-container');
    if (c) SR.showEmpty('term-table-container');
    return;
  }

  // Apply filters
  var compFilter  = document.getElementById('table-comparison-filter');
  var dbFilter    = document.getElementById('table-database-filter');
  var ontFilter   = document.getElementById('table-ontology-filter');
  var dirFilter   = document.getElementById('table-direction-filter');
  var searchText  = document.getElementById('table-search');
  searchText = searchText ? searchText.value.toLowerCase() : '';

  var rows = [];
  for (var i = 0; i < n; i++) {
    if (compFilter && compFilter.value !== 'all' && data.comparison[i] !== compFilter.value) continue;
    if (dbFilter   && dbFilter.value   !== 'all' && data.database[i]   !== dbFilter.value) continue;
    if (ontFilter  && ontFilter.value  !== 'all' && data.ontology[i]   !== ontFilter.value) continue;
    if (dirFilter  && dirFilter.value  !== 'all' && data.input_direction[i] !== dirFilter.value) continue;
    if (searchText) {
      var name = (data.term_name[i] || '').toLowerCase();
      var id   = (data.term_id[i] || '').toLowerCase();
      if (name.indexOf(searchText) === -1 && id.indexOf(searchText) === -1) continue;
    }
    rows.push(i);
  }

  if (rows.length === 0) {
    var c = document.getElementById('term-table-container');
    if (c) c.innerHTML = '<div class="empty-state"><div class="empty-state-text">No terms match the current filters.</div></div>';
    return;
  }

  // Build table with data-result-id on rows (no onclick)
  var html = '<table class="sr-enrichment-table">';
  html += '<thead><tr>';
  var headers = ['Result ID', 'Comparison', 'Database', 'Ontology', 'Term ID', 'Term Name',
                 'p.value', 'p.adjust', 'Gene Ratio', 'Gene Count', 'Direction', 'Genes'];
  headers.forEach(function(h) {
    html += '<th>' + SR.escHtml(h) + '</th>';
  });
  html += '</tr></thead><tbody>';

  rows.forEach(function(i) {
    var sig = data.significant && data.significant[i];
    var rowClass = sig ? 'sr-row-significant' : 'sr-row-non-significant';
    html += '<tr class="' + rowClass + '" data-result-id="' + escapeHtmlAttr(data.result_id ? data.result_id[i] : '') + '">';
    html += '<td class="sr-col-id">'       + SR.escHtml(data.result_id ? data.result_id[i] : '') + '</td>';
    html += '<td class="sr-col-comp">'     + SR.escHtml(data.comparison ? data.comparison[i] : '') + '</td>';
    html += '<td class="sr-col-db">'       + SR.escHtml(data.database ? data.database[i] : '') + '</td>';
    html += '<td class="sr-col-ont">'      + SR.escHtml(data.ontology ? data.ontology[i] : '') + '</td>';
    html += '<td class="sr-col-tid">'      + SR.escHtml(data.term_id ? data.term_id[i] : '') + '</td>';
    html += '<td class="sr-col-name" title="' + escapeHtmlAttr(data.term_name ? data.term_name[i] : '') + '">' + SR.escHtml(data.term_name ? data.term_name[i] : '') + '</td>';
    html += '<td class="sr-col-pval">'     + (data.p_value && data.p_value[i] ? data.p_value[i].toExponential(2) : 'N/A') + '</td>';
    html += '<td class="sr-col-padj">'     + (data.p_adjust && data.p_adjust[i] ? data.p_adjust[i].toExponential(2) : 'N/A') + (sig ? ' *' : '') + '</td>';
    html += '<td class="sr-col-gratio">'   + SR.escHtml(data.gene_ratio ? data.gene_ratio[i] : '') + '</td>';
    html += '<td class="sr-col-count">'    + SR.escHtml(String(data.gene_count ? data.gene_count[i] : '')) + '</td>';
    html += '<td class="sr-col-dir">'      + SR.escHtml(data.input_direction ? data.input_direction[i] : '') + '</td>';
    html += '<td class="sr-col-genes" title="' + escapeHtmlAttr(data.genes ? data.genes[i] : '') + '">' + SR.escHtml(data.genes ? SR.truncateText(data.genes[i], 40) : '') + '</td>';
    html += '</tr>';
  });
  html += '</tbody></table>';

  var container = document.getElementById('term-table-container');
  if (container) container.innerHTML = html;
}

/* ---- Safe attribute value escape for data-result-id ---- */
function escapeHtmlAttr(str) {
  if (str === null || str === undefined) return '';
  return String(str).replace(/&/g, '&amp;').replace(/"/g, '&quot;').replace(/</g, '&lt;').replace(/>/g, '&gt;').replace(/'/g, '&#39;');
}
