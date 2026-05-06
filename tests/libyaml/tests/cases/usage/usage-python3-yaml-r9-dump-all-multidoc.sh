#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r9-dump-all-multidoc
# @title: PyYAML safe_dump_all writes multi-document stream
# @description: Dumps three dicts via safe_dump_all and verifies the result has two '---' separators and reloads back to the same list.
# @timeout: 60
# @tags: usage, python3-yaml
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import yaml
docs = [{'n': 1}, {'n': 2}, {'n': 3}]
text = yaml.safe_dump_all(docs, explicit_start=True)
# explicit_start=True means each doc gets a leading '---'.
assert text.count('---') == 3, text
back = list(yaml.safe_load_all(text))
assert back == docs, (back, docs)
PY
