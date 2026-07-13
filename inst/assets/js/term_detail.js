/* === scReportEnrichment: Term Detail ======================================== */

function sr_populateTermSelect() {
  var model = SR.getModel();
  if (!model || !model.term_details) return;

  var sel = document.getElementById('detail-term-select');
  if (!sel) return;

  while (sel.options.length > 1) sel.remove(1);

  var details = model.term_details;
  Object.keys(details).forEach(function(key) {
    var d = details[key];
    var opt = document.createElement('option');
    opt.value = key;
    opt.textContent = (d.term_id || '?') + ' — ' + SR.truncateText(d.term_name || '', 60);
    sel.appendChild(opt);
  });
}

function sr_showTermDetail() {
  var sel = document.getElementById('detail-term-select');
  if (!sel || !sel.value) return;
  sr_showTermDetailById(sel.value);
}

function sr_showTermDetailById(resultId) {
  var model = SR.getModel();
  if (!model || !model.term_details) return;

  var d = model.term_details[resultId];
  if (!d) return;

  // Navigate to term-detail section
  SR.showSection('term-detail');

  // Set the select value
  var sel = document.getElementById('detail-term-select');
  if (sel) sel.value = resultId;

  var container = document.getElementById('term-detail-content');
  if (!container) return;

  var html = '<div class="detail-card">';
  html += '<div class="detail-header">' + SR.escHtml(d.term_name || 'Unknown') + '</div>';
  html += '<div class="detail-grid">';
  html += detailRow('Term ID', d.term_id);
  html += detailRow('Database', d.database);
  html += detailRow('Ontology', d.ontology);
  html += detailRow('Comparison', d.comparison);
  html += detailRow('p-value', d.p_value !== undefined && d.p_value !== null ? Number(d.p_value).toExponential(2) : 'N/A');
  html += detailRow('p.adjust', d.p_adjust !== undefined && d.p_adjust !== null ? Number(d.p_adjust).toExponential(2) : 'N/A');
  html += detailRow('q-value', d.q_value);
  html += detailRow('Gene Ratio', d.gene_ratio);
  html += detailRow('Background Ratio', d.background_ratio);
  html += detailRow('Gene Count', d.gene_count);
  html += detailRow('Direction', d.input_direction);
  html += detailRow('Species', d.species);
  html += detailRow('Reference Species', d.reference_species);
  html += detailRow('Gene ID Type', d.gene_id_type);
  html += detailRow('Analysis Tool', d.analysis_tool + (d.analysis_tool_version && d.analysis_tool_version !== 'Not provided' ? ' v' + d.analysis_tool_version : ''));
  html += detailRow('p.adjust Method', d.p_adjust_method);
  html += '</div>';

  // Gene list
  html += '<div style="margin-top: 12px;">';
  html += '<div style="font-weight:500; font-size:0.85em; color:var(--sr-muted); margin-bottom:6px;">Associated Genes (' + (d.n_genes || 0) + ')</div>';
  html += '<div class="gene-list">';
  if (d.genes && d.genes.length > 0) {
    d.genes.forEach(function(g) {
      html += '<span class="gene-badge">' + SR.escHtml(g) + '</span>';
    });
  } else {
    html += '<span style="color:var(--sr-muted); font-size:0.85em;">No genes provided</span>';
  }
  html += '</div></div>';

  html += '</div>'; // detail-card
  container.innerHTML = html;
}

function detailRow(label, value) {
  if (value === null || value === undefined) value = 'Not provided';
  return '<div class="detail-label">' + SR.escHtml(label) + '</div>' +
         '<div class="detail-value">' + SR.escHtml(String(value)) + '</div>';
}

// Also navigate via term-select dropdown
document.addEventListener('DOMContentLoaded', function() {
  setTimeout(function() {
    var sel = document.getElementById('detail-term-select');
    if (sel) sel.addEventListener('change', sr_showTermDetail);
  }, 200);
});
