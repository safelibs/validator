#!/usr/bin/env bash
# @testcase: usage-python3-yaml-marked-error-line-batch18
# @title: PyYAML MarkedYAMLError exposes problem_mark line and column for a malformed document
# @description: Feeds a deliberately malformed YAML document (mixed flow-block sequence) to yaml.safe_load, catches the resulting yaml.YAMLError (a MarkedYAMLError subclass), and verifies the exception carries a problem_mark attribute with line and column attributes, that the error class is a subclass of yaml.YAMLError, and that re-raising as a yaml.MarkedYAMLError still surfaces the same coordinates so callers can render contextual error reports.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-marked-error-line-batch18"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

# The flow sequence "[1, 2," is left open and then interleaved with a block
# entry on the next line, which is a parser-level error.
bad_doc = "items: [1, 2,\n  - bad\n"

caught = None
try:
    yaml.safe_load(bad_doc)
except yaml.YAMLError as exc:
    caught = exc

assert caught is not None, "expected yaml.YAMLError"

# MarkedYAMLError is the standard parent for parser/scanner/constructor errors.
assert isinstance(caught, yaml.MarkedYAMLError), type(caught)
assert isinstance(caught, yaml.YAMLError), type(caught)

mark = getattr(caught, "problem_mark", None)
assert mark is not None, "expected problem_mark on MarkedYAMLError"
# 0-indexed line/column.
assert isinstance(mark.line, int), type(mark.line)
assert isinstance(mark.column, int), type(mark.column)
assert mark.line >= 0, mark.line
assert mark.column >= 0, mark.column
# The malformed token sits beyond column 0 of one of the first two lines.
assert mark.line in (0, 1, 2), mark.line

# str() on a MarkedYAMLError surfaces the line:column position for humans.
text = str(caught)
assert "line" in text or f"line {mark.line + 1}" in text, text

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"class={type(caught).__name__}\n")
    fh.write(f"line={mark.line}\n")
    fh.write(f"column={mark.column}\n")

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "class="
validator_assert_contains "$tmpdir/out" "line="
validator_assert_contains "$tmpdir/out" "column="
echo "OK"
