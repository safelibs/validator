#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-stream-file-like-batch15
# @title: PyYAML dump writes through a passed file-like stream
# @description: Calls yaml.dump with an explicit stream= argument bound to an opened text-mode file handle, verifies that yaml.dump returns None (no in-memory string), and confirms the same content is materialized on disk via the stream. Then repeats the call with an io.StringIO buffer to confirm the same protocol works for in-memory streams.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-stream-file-like-batch15"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml" "$tmpdir/result"
import io
import sys
import yaml

case_id = sys.argv[1]
file_dst = sys.argv[2]
result_dst = sys.argv[3]

data = {"name": "alpha", "items": [1, 2, 3]}

# 1) File-handle stream: yaml.dump should return None when stream= is provided.
with open(file_dst, "w", encoding="utf-8") as fh:
    rv = yaml.dump(data, stream=fh, default_flow_style=False, sort_keys=True)
assert rv is None, rv

with open(file_dst, "r", encoding="utf-8") as fh:
    file_text = fh.read()
assert "name: alpha" in file_text, file_text
assert "- 1" in file_text, file_text

# 2) io.StringIO stream: same return-value contract.
buf = io.StringIO()
rv2 = yaml.dump(data, stream=buf, default_flow_style=False, sort_keys=True)
assert rv2 is None, rv2
buf_text = buf.getvalue()
assert buf_text == file_text, (buf_text, file_text)

# Round-trip through safe_load to confirm the emitted content is well-formed.
loaded_file = yaml.safe_load(file_text)
loaded_buf = yaml.safe_load(buf_text)
assert loaded_file == data, loaded_file
assert loaded_buf == data, loaded_buf

with open(result_dst, "w", encoding="utf-8") as fh:
    fh.write(f"return_file={rv!r}\n")
    fh.write(f"return_buf={rv2!r}\n")
    fh.write(f"match={file_text == buf_text}\n")

print("STREAM_OK")
PYCASE

validator_assert_contains "$tmpdir/result" "return_file=None"
validator_assert_contains "$tmpdir/result" "return_buf=None"
validator_assert_contains "$tmpdir/result" "match=True"
validator_assert_contains "$tmpdir/out.yaml" "name: alpha"
echo "OK"
