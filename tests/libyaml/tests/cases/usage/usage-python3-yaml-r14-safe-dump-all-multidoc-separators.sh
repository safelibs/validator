#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r14-safe-dump-all-multidoc-separators
# @title: PyYAML safe_dump_all emits a "---" separator between two documents
# @description: Dumps a list of two distinct mappings via safe_dump_all and asserts the resulting string contains the document separator marker on its own line between the documents, then round-trips the output through safe_load_all to recover both source documents in order.
# @timeout: 60
# @tags: usage, python3-yaml, safedump, multidoc
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = [{'a': 1}, {'b': 2}]
out = yaml.safe_dump_all(src)
# The serialized form must carry exactly one "---" separator between the two documents.
assert out.count('---\n') == 1, out
# Round-trip through safe_load_all must recover both documents in declared order.
got = list(yaml.safe_load_all(out))
assert got == src, (got, src)
PY
