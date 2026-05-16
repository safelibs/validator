#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r21-safe-load-explicit-omap-tag-yields-list-of-tuples
# @title: PyYAML safe_load !!omap yields a list of single-key dicts in declared order
# @description: Parses a document tagged !!omap with three key-value pairs in non-alphabetical order and asserts the result is a list whose entries are single-key dicts preserving the source order — pinning libyaml's !!omap construction through python3-yaml's safe loader.
# @timeout: 60
# @tags: usage, python3-yaml, safe-load, omap, ordered, r21
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = """
!!omap
- charlie: 3
- alpha: 1
- bravo: 2
"""
data = yaml.safe_load(doc)
assert isinstance(data, list) and len(data) == 3, data
# Each entry must be a 2-tuple (key, value) ordered as declared.
for entry in data:
    assert isinstance(entry, tuple) and len(entry) == 2, entry
keys = [entry[0] for entry in data]
values = [entry[1] for entry in data]
assert keys == ['charlie', 'alpha', 'bravo'], keys
assert values == [3, 1, 2], values
PY
