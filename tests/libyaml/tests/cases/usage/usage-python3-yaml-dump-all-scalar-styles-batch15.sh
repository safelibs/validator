#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-all-scalar-styles-batch15
# @title: PyYAML dump emits each scalar style on demand
# @description: Drives yaml.dump with default_style set to each of the documented scalar styles ('"', "'", "", "|", ">") on the same string payload and verifies each style is reflected in the emitted output (double quotes, single quotes, plain, literal block, and folded block respectively).
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-all-scalar-styles-batch15"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml

case_id = sys.argv[1]
out_path = sys.argv[2]

payload = "alpha line"
results = {}
for style_name, style in [
    ("double", '"'),
    ("single", "'"),
    ("plain", ""),
    ("literal", "|"),
    ("folded", ">"),
]:
    text = yaml.dump(payload, default_style=style)
    results[style_name] = text

# Each style leaves a recognizable marker in the output.
assert '"alpha line"' in results["double"], results["double"]
assert "'alpha line'" in results["single"], results["single"]
# Plain style: no leading quote/pipe/gt char before the value.
plain = results["plain"].strip()
assert plain.startswith("alpha"), plain
assert "|" in results["literal"], results["literal"]
assert ">" in results["folded"], results["folded"]

# All five emitters round-trip back to the original string under safe_load.
for style_name, text in results.items():
    loaded = yaml.safe_load(text)
    assert loaded == payload, (style_name, loaded, text)

with open(out_path, "w", encoding="utf-8") as fh:
    for k, v in results.items():
        fh.write(f"--- {k} ---\n{v}")
    fh.write("STYLES_OK %d\n" % len(results))

print("STYLES_OK", len(results))
PYCASE

validator_assert_contains "$tmpdir/out" "STYLES_OK"
validator_assert_contains "$tmpdir/out" '"alpha line"'
validator_assert_contains "$tmpdir/out" "'alpha line'"
echo "OK"
