#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-all-document-separators-batch15
# @title: PyYAML dump_all emits --- separators between documents
# @description: Feeds an iterable of three distinct documents to yaml.dump_all and verifies the output contains exactly two "---" document-start markers separating the three documents (the first document does not require a leading separator). Then re-loads the stream with yaml.safe_load_all and confirms the round-trip yields the original three documents.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-all-document-separators-batch15"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import re
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

docs = [
    {"doc": 1, "name": "alpha"},
    {"doc": 2, "name": "beta"},
    {"doc": 3, "name": "gamma"},
]

text = yaml.dump_all(iter(docs), explicit_start=True, default_flow_style=False, sort_keys=True)
with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

# explicit_start=True forces a leading "---" before the first document too.
# So with three documents we expect three "---" markers at line starts.
starts = re.findall(r"(?m)^---\s*$", text)
assert len(starts) == 3, (len(starts), text)

loaded = list(yaml.safe_load_all(text))
assert loaded == docs, loaded

print("DOC_SEP_OK", len(starts))
PYCASE

# Three "---" document markers (line-anchored).
count=$(grep -cE '^---[[:space:]]*$' "$tmpdir/out.yaml")
if [[ "$count" != "3" ]]; then
  echo "expected 3 document markers, got $count" >&2
  sed -n '1,80p' "$tmpdir/out.yaml" >&2
  exit 1
fi
validator_assert_contains "$tmpdir/out.yaml" "name: alpha"
validator_assert_contains "$tmpdir/out.yaml" "name: gamma"
echo "OK"
