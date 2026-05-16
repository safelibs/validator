#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r21-safe-load-explicit-set-tag-yields-python-set
# @title: PyYAML safe_load !!set with mapping-of-nulls yields a Python set of the keys
# @description: Parses a document tagged !!set whose entries are mapping keys to null and asserts safe_load returns a Python set object equal to {'a', 'b', 'c'} — pinning libyaml's !!set construction through python3-yaml's safe loader.
# @timeout: 60
# @tags: usage, python3-yaml, safe-load, set, r21
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = """
!!set
? a
? b
? c
"""
data = yaml.safe_load(doc)
assert isinstance(data, set), (type(data), data)
assert data == {'a', 'b', 'c'}, data
PY
