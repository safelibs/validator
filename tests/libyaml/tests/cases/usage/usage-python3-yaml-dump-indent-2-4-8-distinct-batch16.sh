#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-indent-2-4-8-distinct-batch16
# @title: PyYAML yaml.dump indent=2 vs 4 vs 8 produce distinct outputs
# @description: Dumps the same nested mapping three times with indent=2, 4, and 8 and verifies the three serializations differ from each other and use the expected step widths for the inner key.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-indent-2-4-8-distinct-batch16"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir"
import os
import sys
import yaml

case_id = sys.argv[1]
out_dir = sys.argv[2]

value = {"outer": {"inner": {"leaf": 1}}}

texts = {}
for indent in (2, 4, 8):
    texts[indent] = yaml.dump(
        value,
        indent=indent,
        default_flow_style=False,
        sort_keys=False,
    )
    with open(os.path.join(out_dir, f"indent{indent}.yaml"), "w", encoding="utf-8") as fh:
        fh.write(texts[indent])

# All three outputs must be distinct.
assert texts[2] != texts[4], (texts[2], texts[4])
assert texts[4] != texts[8], (texts[4], texts[8])
assert texts[2] != texts[8], (texts[2], texts[8])

# Verify the leading-space indent for the "inner:" line in each variant.
def first_indent_for(text, key):
    for line in text.splitlines():
        stripped = line.lstrip()
        if stripped.startswith(key):
            return len(line) - len(stripped)
    raise AssertionError(f"key {key!r} not found in {text!r}")

assert first_indent_for(texts[2], "inner:") == 2, texts[2]
assert first_indent_for(texts[4], "inner:") == 4, texts[4]
assert first_indent_for(texts[8], "inner:") == 8, texts[8]

# All three must round-trip back to the same value.
for indent, text in texts.items():
    assert yaml.safe_load(text) == value, (indent, text)

print("OK")
PYCASE

# Sanity-check the inner indentation in the rendered files.
grep -q '^  inner:' "$tmpdir/indent2.yaml"
grep -q '^    inner:' "$tmpdir/indent4.yaml"
grep -q '^        inner:' "$tmpdir/indent8.yaml"
echo "OK"
