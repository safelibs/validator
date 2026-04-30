#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-allow-unicode-utf8-batch12
# @title: PyYAML dump allow unicode UTF-8 bytes
# @description: Dumps non-ASCII scalars with yaml.dump allow_unicode=True and verifies the literal characters and their UTF-8 encoded bytes appear in the output.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-allow-unicode-utf8-batch12"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

data = {"greeting": "café", "kanji": "漢字"}
text = yaml.dump(data, allow_unicode=True, default_flow_style=False, sort_keys=True)

assert "café" in text, text
assert "漢字" in text, text
# When allow_unicode=False, PyYAML would escape these. Confirm they are NOT escaped here.
assert "\\u" not in text, text

with open(dst, "wb") as fh:
    fh.write(text.encode("utf-8"))

print("LEN", len(text))
print("OK")
PYCASE

# Confirm UTF-8 bytes for cafe (c3 a9) are present in the file.
python3 - <<'PYCHECK' "$tmpdir/out.yaml"
import sys
data = open(sys.argv[1], "rb").read()
assert b"\xc3\xa9" in data, data
assert b"\xe6\xbc\xa2\xe5\xad\x97" in data, data
print("UTF8_OK")
PYCHECK

echo "OK"
