#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r20-safe-load-all-two-docs-list-length-two
# @title: PyYAML safe_load_all on a two-document stream returns exactly two parsed documents
# @description: Feeds 'a: 1\n---\nb: 2\n' to yaml.safe_load_all, collects the iterator into a list and asserts the length is exactly 2 with the documents equal to {'a':1} and {'b':2} in order — pinning libyaml's multi-document iterator.
# @timeout: 60
# @tags: usage, python3-yaml, safe-load-all, multi-doc, r20
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

stream = 'a: 1\n---\nb: 2\n'
docs = list(yaml.safe_load_all(stream))
assert len(docs) == 2, docs
assert docs[0] == {'a': 1}, docs[0]
assert docs[1] == {'b': 2}, docs[1]
PY
