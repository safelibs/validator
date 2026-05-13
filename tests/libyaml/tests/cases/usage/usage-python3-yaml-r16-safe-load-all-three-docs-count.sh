#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r16-safe-load-all-three-docs-count
# @title: PyYAML safe_load_all materializes exactly three documents from a triple-doc YAML stream
# @description: Feeds yaml.safe_load_all a stream of three '---'-separated documents (mapping, list, scalar) and asserts the materialized list has length 3 with the expected per-document types and values.
# @timeout: 60
# @tags: usage, python3-yaml, multidoc, safedump
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

stream = """---
a: 1
b: 2
---
- one
- two
- three
---
just-a-scalar
"""
docs = list(yaml.safe_load_all(stream))
assert len(docs) == 3, len(docs)
assert docs[0] == {'a': 1, 'b': 2}, docs[0]
assert docs[1] == ['one', 'two', 'three'], docs[1]
assert docs[2] == 'just-a-scalar', docs[2]
PY
