/* === scReportEnrichment: JS behavior tests (Round 4) ======================== */
/* Tests the PRODUCTION enrichment_plot_utils.js via CommonJS require().        */

var path = require('path');
var utils = require(path.join(__dirname, '../../inst/assets/js/enrichment_plot_utils.js'));

// Verify we loaded the real production module
console.assert(typeof utils.isFiniteNumber === 'function', 'isFiniteNumber should be a function');
console.assert(typeof utils.compareNumeric === 'function', 'compareNumeric should be a function');
console.assert(typeof utils.filterIndices === 'function', 'filterIndices should be a function');
console.assert(typeof utils.sortIndices === 'function', 'sortIndices should be a function');
console.assert(typeof utils.takeTopN === 'function', 'takeTopN should be a function');

// ---- Test data ----
var testData = {
  term_name:       ['A', 'B', 'C', 'D', 'E'],
  comparison:      ['c1', 'c1', 'c1', 'c2', 'c2'],
  database:        ['GO', 'GO', 'KEGG', 'GO', 'GO'],
  ontology:        ['BP', 'BP', 'BP', 'CC', 'BP'],
  input_direction: ['up', 'up', 'up', 'down', 'up'],
  p_adjust:        [0.001, 0.010, 0.020, 0.005, null],
  gene_count:      [2, 100, 50, 30, 10],
  gene_ratio_num:  [0.01, 0.50, 0.80, 0.30, 0.05]
};

// Missing value data for sorting
var missingData = {
  term_name:       ['M1', 'M2', 'M3', 'M4', 'M5'],
  comparison:      ['c1', 'c1', 'c1', 'c1', 'c1'],
  database:        ['GO', 'GO', 'GO', 'GO', 'GO'],
  ontology:        ['BP', 'BP', 'BP', 'BP', 'BP'],
  input_direction: ['up', 'up', 'up', 'up', 'up'],
  p_adjust:        [0.01, null, 0, NaN, 0.05],
  gene_count:      [10, null, 100, NaN, 50],
  gene_ratio_num:  [0.1, undefined, 0.8, Infinity, 0.4]
};

// ---- Assertion helpers ----
var passed = 0, failed = 0;

function assertEqual(actual, expected, msg) {
  var eq = JSON.stringify(actual) === JSON.stringify(expected);
  if (eq) { passed++; }
  else {
    failed++;
    console.error('FAIL: ' + msg + '\n  expected: ' + JSON.stringify(expected) + '\n  actual:   ' + JSON.stringify(actual));
    process.exitCode = 1;
  }
}

function assertTrue(cond, msg) {
  if (cond) { passed++; }
  else { failed++; console.error('FAIL: ' + msg); process.exitCode = 1; }
}

// ---- Tests ----

// --- Basic sorting correctness ---

// 1. p_adjust ascending: A(0.001) first
var sorted = utils.sortIndices([0,1,2,3], testData, 'p_adjust');
assertEqual(sorted[0], 0, 'p_adjust sort: A first');

// 2. gene_count descending: B(100) first
sorted = utils.sortIndices([0,1,2,3], testData, 'gene_count');
assertEqual(sorted[0], 1, 'gene_count sort: B first');

// 3. gene_ratio descending: C(0.80) first
sorted = utils.sortIndices([0,1,2,3], testData, 'gene_ratio');
assertEqual(sorted[0], 2, 'gene_ratio sort: C first');

// 4. top_n=2
var filtered = utils.sortIndices([0,1,2,3], testData, 'gene_count');
var top2 = utils.takeTopN(filtered, 2);
assertEqual(top2.length, 2, 'top_n=2 returns 2');

// 5. p_adjust=0 is best (sorted first)
var zeroData = { term_name: ['Z','Y'], p_adjust: [0, 0.001], gene_count: [5,10], gene_ratio_num: [0.1,0.2] };
sorted = utils.sortIndices([0,1], zeroData, 'p_adjust');
assertEqual(sorted[0], 0, 'p_adjust=0 sorts first');

// --- Missing value sorting ---

// 6. p_adjust ascending: null last, 0 best
sorted = utils.sortIndices([0,1,2,3,4], missingData, 'p_adjust');
// Expected order: 0(0), 0.01(0.01), 0.05(0.05), null(NaN)
// Indices: 2(p=0), 0(p=0.01), 4(p=0.05), then 1(null), 3(NaN)
assertEqual(sorted[0], 2, 'p_adjust asc: 0 first');
assertEqual(sorted[1], 0, 'p_adjust asc: 0.01 second');
assertEqual(sorted[2], 4, 'p_adjust asc: 0.05 third');
// Last two are null/NaN (exact order of missing among themselves doesn't matter)
assertTrue(sorted[3] === 1 || sorted[3] === 3, 'missing values at end');

// 7. gene_count descending: missing last
sorted = utils.sortIndices([0,1,2,3,4], missingData, 'gene_count');
// 100(2), 50(4), 10(0), then missing(1,3)
assertEqual(sorted[0], 2, 'gene_count desc: 100 first');
assertEqual(sorted[1], 4, 'gene_count desc: 50 second');
assertEqual(sorted[2], 0, 'gene_count desc: 10 third');
sorted.slice(3).forEach(function(i) {
  assertTrue(i === 1 || i === 3, 'gene_count missing at end: ' + i);
});

// 8. gene_ratio descending: missing last
sorted = utils.sortIndices([0,1,2,3,4], missingData, 'gene_ratio');
// 0.8(2), 0.4(4), 0.1(0), then missing(1,3)
assertEqual(sorted[0], 2, 'gene_ratio desc: 0.8 first');
assertEqual(sorted[1], 4, 'gene_ratio desc: 0.4 second');
assertEqual(sorted[2], 0, 'gene_ratio desc: 0.1 third');

// 9. compareNumeric: 0 is a valid finite number
assertEqual(utils.compareNumeric(0, null, true), -1, '0 vs null ascending: 0 before null');
assertEqual(utils.compareNumeric(0, null, false), -1, '0 vs null descending: 0 before null');
assertEqual(utils.compareNumeric(0, 1, true), -1, '0 < 1 ascending');
assertEqual(utils.compareNumeric(0, 1, false), 1, '0 < 1 descending → 1 comes first');

// 10. isFiniteNumber: 0 is true
assertTrue(utils.isFiniteNumber(0) === true, '0 is finite');
assertTrue(utils.isFiniteNumber(NaN) === false, 'NaN is not finite');
assertTrue(utils.isFiniteNumber(null) === false, 'null is not finite');
assertTrue(utils.isFiniteNumber(Infinity) === false, 'Infinity is not finite');
assertTrue(utils.isFiniteNumber(-Infinity) === false, '-Infinity is not finite');
assertTrue(utils.isFiniteNumber(undefined) === false, 'undefined is not finite');

// --- Filters ---

// 11. Comparison filter
assertEqual(utils.filterIndices(testData, { comparison: 'c1' }).length, 3);
assertEqual(utils.filterIndices(testData, { comparison: 'c2' }).length, 2);

// 12. Ontology filter
var ont = utils.filterIndices(testData, { ontology: 'BP' });
assertEqual(ont.length, 4, 'ontology=BP: 4 items');
ont = utils.filterIndices(testData, { ontology: 'CC' });
assertEqual(ont.length, 1, 'ontology=CC: 1 item');
assertEqual(testData.term_name[ont[0]], 'D');

// 13. Combined filter
assertEqual(utils.filterIndices(testData, { comparison: 'c1', ontology: 'BP' }).length, 3);

// 14. Database filter
assertEqual(utils.filterIndices(testData, { database: 'KEGG' }).length, 1);

// 15. Direction filter
assertEqual(utils.filterIndices(testData, { direction: 'down' }).length, 1);

// 16. All filters
assertEqual(utils.filterIndices(testData, { comparison: 'all' }).length, 5);

// --- Pipeline ---

// 17. Full pipeline: filter c1, sort gene_count desc, take top 2 → B(100), C(50)
var pipeline = utils.filterIndices(testData, { comparison: 'c1' });
pipeline = utils.sortIndices(pipeline, testData, 'gene_count');
pipeline = utils.takeTopN(pipeline, 2);
assertEqual(pipeline, [1, 2], 'full pipeline');

// 18. top_n larger than result returns all
pipeline = utils.filterIndices(testData, { comparison: 'c1' });
pipeline = utils.sortIndices(pipeline, testData, 'p_adjust');
pipeline = utils.takeTopN(pipeline, 50);
assertEqual(pipeline.length, 3, 'top_n=50 returns 3');

// 19. Empty indices
assertEqual(utils.sortIndices([], testData, 'p_adjust').length, 0);

// 20. Original indices not mutated
var original = [2, 0, 1];
var sorted2 = utils.sortIndices(original, testData, 'p_adjust');
assertTrue(original[0] === 2 && original[1] === 0, 'original not mutated');
assertTrue(sorted2 !== original, 'returns new array');

// ---- Summary ----
console.log('JavaScript behavior tests: ' + passed + ' passed, ' + failed + ' failed');
if (failed > 0) process.exit(1);
