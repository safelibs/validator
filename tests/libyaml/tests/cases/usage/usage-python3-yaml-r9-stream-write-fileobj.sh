#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r9-stream-write-fileobj
# @title: PyYAML safe_dump streams to a file object
# @description: Opens a temp file for writing, passes it as the stream argument to yaml.safe_dump, and asserts the file content reloads back to the original dict.
# @timeout: 60
# @tags: usage, python3-yaml
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

out="$tmpdir/out.yaml"
python3 - "$out" <<'PY'
import sys, yaml
data = {'host': 'localhost', 'port': 8080, 'tags': ['a', 'b']}
with open(sys.argv[1], 'w', encoding='utf-8') as fh:
    yaml.safe_dump(data, fh, sort_keys=True)
with open(sys.argv[1], 'r', encoding='utf-8') as fh:
    back = yaml.safe_load(fh)
assert back == data, (back, data)
PY

# File must be non-empty.
test -s "$out"
