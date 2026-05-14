#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r17-serialize-node-roundtrip
# @title: PyYAML yaml.serialize over a composed Node round-trips back through safe_load
# @description: Composes a mapping document to a Node via yaml.compose, re-serializes it via yaml.serialize, and asserts the serialized text loads back via yaml.safe_load to the same Python value — exercising the compose/serialize pair as inverses for safe content.
# @timeout: 60
# @tags: usage, python3-yaml, serialize, roundtrip
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = "a: 1\nb:\n  - 2\n  - 3\n"
node = yaml.compose(src)
text = yaml.serialize(node)
out = yaml.safe_load(text)
assert out == {'a': 1, 'b': [2, 3]}, out
PY
