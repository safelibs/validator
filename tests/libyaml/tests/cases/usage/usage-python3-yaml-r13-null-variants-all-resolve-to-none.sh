#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r13-null-variants-all-resolve-to-none
# @title: PyYAML safe_load resolves all five null spellings to Python None
# @description: Loads a mapping whose values exercise the five YAML 1.1 null spellings (~, empty, null, Null, NULL) and asserts safe_load resolves every one of them to the singleton Python None.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, null
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "a: ~\nb:\nc: null\nd: Null\ne: NULL\n"
data = yaml.safe_load(doc)
for k in ('a', 'b', 'c', 'd', 'e'):
    assert data[k] is None, (k, data[k])
PY
