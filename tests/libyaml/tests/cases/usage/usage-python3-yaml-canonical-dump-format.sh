#!/usr/bin/env bash
# @testcase: usage-python3-yaml-canonical-dump-format
# @title: PyYAML CSafeDumper canonical output format
# @description: Emits a mapping with canonical=True via CSafeDumper and verifies fully-tagged canonical YAML output that round-trips through CSafeLoader.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - "$tmpdir/canon.yaml" <<'PY'
import sys
import yaml

dst = sys.argv[1]
value = {"name": "alpha", "count": 3}
text = yaml.dump(value, Dumper=yaml.CSafeDumper, canonical=True)

# Canonical form starts with `---` and contains explicit tags such as
# `!!map`, `!!str`, `!!int`.
assert text.startswith("---"), text
assert "!!map" in text, text
assert "!!str" in text, text
assert "!!int" in text, text

# Round-trip back to the same value.
back = yaml.load(text, Loader=yaml.CSafeLoader)
assert back == value, back

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

print("CANON_OK")
PY

validator_assert_contains "$tmpdir/canon.yaml" '!!map'
validator_assert_contains "$tmpdir/canon.yaml" '!!str'
validator_assert_contains "$tmpdir/canon.yaml" '!!int'
echo "OK"
