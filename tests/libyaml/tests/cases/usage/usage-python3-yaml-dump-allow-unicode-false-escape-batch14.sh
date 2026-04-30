#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-allow-unicode-false-escape-batch14
# @title: PyYAML dump allow_unicode=False escapes non-ASCII
# @description: Dumps non-ASCII scalars with yaml.dump allow_unicode=False and verifies PyYAML emits backslash-u escape sequences instead of the literal characters, contrasting with allow_unicode=True.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-allow-unicode-false-escape-batch14"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/escaped.yaml" "$tmpdir/literal.yaml"
import sys
import yaml

case_id = sys.argv[1]
escaped_path = sys.argv[2]
literal_path = sys.argv[3]

data = {"greeting": "café", "kanji": "漢字"}

escaped = yaml.dump(data, allow_unicode=False, default_flow_style=False, sort_keys=True)
literal = yaml.dump(data, allow_unicode=True, default_flow_style=False, sort_keys=True)

with open(escaped_path, "w", encoding="ascii") as fh:
    fh.write(escaped)
with open(literal_path, "w", encoding="utf-8") as fh:
    fh.write(literal)

# allow_unicode=False output must be pure ASCII and must contain \u escapes.
escaped.encode("ascii")
assert "\\u" in escaped, escaped
assert "café" not in escaped, escaped
assert "漢字" not in escaped, escaped

# allow_unicode=True keeps the literal characters and uses no \u escapes.
assert "café" in literal, literal
assert "漢字" in literal, literal
assert "\\u" not in literal, literal

# Both round-trip to the same Python value.
assert yaml.safe_load(escaped) == data
assert yaml.safe_load(literal) == data

print("OK")
PYCASE

# Bytes-level check: escaped file must not contain UTF-8 bytes for é.
python3 - <<'PYCHECK' "$tmpdir/escaped.yaml" "$tmpdir/literal.yaml"
import sys
escaped = open(sys.argv[1], "rb").read()
literal = open(sys.argv[2], "rb").read()
assert b"\xc3\xa9" not in escaped, escaped
assert b"\xc3\xa9" in literal, literal
print("BYTES_OK")
PYCHECK

validator_assert_contains "$tmpdir/escaped.yaml" "\\u"
echo "OK"
