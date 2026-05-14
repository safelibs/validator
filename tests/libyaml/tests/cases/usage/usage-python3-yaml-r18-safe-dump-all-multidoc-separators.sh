#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r18-safe-dump-all-multidoc-separators
# @title: PyYAML safe_dump_all writes multiple documents separated by triple-dash markers
# @description: Dumps a list of three mappings via yaml.safe_dump_all with explicit_start=True, asserts the output contains exactly three '---' document-start markers, and that safe_load_all reads back the same three documents.
# @timeout: 60
# @tags: usage, python3-yaml, safe-dump-all, multidoc, r18
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

docs = [{'n': 1}, {'n': 2}, {'n': 3}]
out = yaml.safe_dump_all(docs, explicit_start=True)
markers = [line for line in out.splitlines() if line == '---']
assert len(markers) == 3, (markers, out)

reloaded = list(yaml.safe_load_all(out))
assert reloaded == docs, reloaded
PY
