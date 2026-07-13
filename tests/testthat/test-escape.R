# Test: utils.R — escape helpers & ID scoping ==================================

context("Utilities - Round 2")

# ---- Escape helpers ----

test_that("escape_html_text handles basic characters", {
  expect_equal(escape_html_text("<script>"), "&lt;script&gt;")
  expect_equal(escape_html_text('"test"'), "&quot;test&quot;")
  expect_equal(escape_html_text("A & B"), "A &amp; B")
})

test_that("escape_html_text handles NULL and NA", {
  expect_equal(escape_html_text(NULL), "Not provided")
  expect_equal(escape_html_text(NA), "Not provided")
})

test_that("escape_html_attribute escapes single quotes", {
  expect_match(escape_html_attribute("it's"), "&#39;")
})

test_that("escape_json_for_script prevents </script> in payload", {
  payload <- '{"name": "</script><script>alert(1)</script>"}'
  escaped <- escape_json_for_script(payload)
  # Should not contain literal </script>
  expect_false(grepl("</script>", escaped, fixed = TRUE))
  expect_false(grepl("</Script>", escaped, ignore.case = TRUE))
  expect_false(grepl("<script>", escaped, fixed = TRUE))
})

test_that("escape_json_for_script handles unicode escapes", {
  payload <- '{"name": "<test> & more"}'
  escaped <- escape_json_for_script(payload)
  expect_match(escaped, "\\\\u003c")
  expect_match(escaped, "\\\\u003e")
  expect_match(escaped, "\\\\u0026")
})

test_that("escape_json_for_script preserves valid JSON structure", {
  payload <- jsonlite::toJSON(list(name = "hello", value = 42), auto_unbox = TRUE)
  escaped <- escape_json_for_script(payload)
  # After unescaping the script-safe form, it should parse
  # \u003c -> <, \u003e -> >, \u0026 -> &
  restored <- gsub("\\\\u003c", "<", escaped, fixed = TRUE)
  restored <- gsub("\\\\u003e", ">", restored, fixed = TRUE)
  restored <- gsub("\\\\u0026", "&", restored, fixed = TRUE)
  parsed <- jsonlite::fromJSON(restored)
  expect_equal(parsed$name, "hello")
  expect_equal(parsed$value, 42)
})

test_that("escape_json_for_script handles U+2028/U+2029", {
  payload <- '{"data": "line1\u2028line2\u2029line3"}'
  escaped <- escape_json_for_script(payload)
  expect_match(escaped, "\\\\u2028")
  expect_match(escaped, "\\\\u2029")
})

# ---- make_scoped_result_ids ----

test_that("make_scoped_result_ids produces correct format", {
  ids <- make_scoped_result_ids(3, "B_cell")
  expect_equal(ids, c("B_cell__ORA_0001", "B_cell__ORA_0002", "B_cell__ORA_0003"))
})

test_that("make_scoped_result_ids sanitises special comparison chars", {
  ids <- make_scoped_result_ids(2, "B cell's test!")
  # Should have no spaces, quotes, or exclamation marks
  expect_false(any(grepl("[ '!]", ids)))
  # Should start with sanitised comparison
  expect_match(ids[1], "^B_cell_s_test__ORA_")
})

test_that("make_scoped_result_ids handles chinese characters", {
  ids <- make_scoped_result_ids(2, "中文名称")
  # Chinese chars become underscores
  expect_false(any(grepl("[\\x{4e00}-\\x{9fff}]", ids, perl = TRUE)))
})

test_that("make_scoped_result_ids avoids existing IDs", {
  existing <- c("B_cell__ORA_0001")
  ids <- make_scoped_result_ids(3, "B_cell", existing_ids = existing)
  expect_equal(length(ids), 3)
  expect_equal(length(unique(c(existing, ids))), 4)  # all unique
})
