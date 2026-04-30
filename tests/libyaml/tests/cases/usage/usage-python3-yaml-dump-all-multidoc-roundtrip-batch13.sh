#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-all-multidoc-roundtrip-batch13
# @title: PyYAML dump_all over multi-document round-trip
# @description: Dumps a list of documents with yaml.dump_all and verifies safe_load_all reproduces all documents in order.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-all-multidoc-roundtrip-batch13"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

docs = [
    {"doc": 1, "name": "alpha"},
    {"doc": 2, "name": "beta"},
    {"doc": 3, "name": "gamma"},
]
text = yaml.dump_all(docs, default_flow_style=False)
assert text.count("---") >= 2, text

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

loaded = list(yaml.safe_load_all(text))
assert loaded == docs, loaded
print("DOCS", len(loaded))
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "alpha"
validator_assert_contains "$tmpdir/out.yaml" "beta"
validator_assert_contains "$tmpdir/out.yaml" "gamma"
grep -c -- "---" "$tmpdir/out.yaml" >/dev/null
echo "OK"
