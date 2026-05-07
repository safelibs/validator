#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r12-safe-load-all-list-three-docs
# @title: PyYAML safe_load_all yields three documents in order
# @description: Iterates safe_load_all over a three-document stream and asserts the resulting list has exactly three elements in stream order, with each document a distinct dict.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, multidoc
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

stream = "id: 1\nname: a\n---\nid: 2\nname: b\n---\nid: 3\nname: c\n"
docs = list(yaml.safe_load_all(stream))
assert len(docs) == 3, len(docs)
assert docs[0] == {'id': 1, 'name': 'a'}, docs[0]
assert docs[1] == {'id': 2, 'name': 'b'}, docs[1]
assert docs[2] == {'id': 3, 'name': 'c'}, docs[2]
PY
