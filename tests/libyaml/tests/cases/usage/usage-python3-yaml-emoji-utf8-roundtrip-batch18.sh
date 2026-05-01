#!/usr/bin/env bash
# @testcase: usage-python3-yaml-emoji-utf8-roundtrip-batch18
# @title: PyYAML safe_dump with allow_unicode=True round-trips multi-byte emoji scalars verbatim
# @description: Calls yaml.safe_dump with allow_unicode=True on a dict containing emoji code points outside the BMP and a CJK string, verifies the emitted text contains the literal multi-byte characters (not \\uXXXX escapes), then reloads with yaml.safe_load and confirms exact equality with the original strings as well as preservation of Python str length (code-point count) and UTF-8 byte length.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-emoji-utf8-roundtrip-batch18"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

# Party popper U+1F389 (4 UTF-8 bytes) and CJK characters.
original = {
    "msg": "hello \U0001F389 world",
    "cjk": "你好",
    "label": "ascii-only",
}

text = yaml.safe_dump(original, allow_unicode=True, default_flow_style=False, sort_keys=True)

# Literal characters are present (not \uXXXX escapes).
assert "\U0001F389" in text, text
assert "你好" in text, text
assert "\\u" not in text, text
assert "\\U" not in text, text

# Round-trip via safe_load.
with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

with open(dst, "r", encoding="utf-8") as fh:
    raw = fh.read()
loaded = yaml.safe_load(raw)
assert loaded == original, loaded

# Code-point counts survive (Python str.len = code points).
assert len(loaded["msg"]) == len(original["msg"]), (loaded["msg"], original["msg"])
assert len(loaded["cjk"]) == 2, loaded["cjk"]
# UTF-8 byte length: emoji is 4 bytes, "hello " 6, " world" 6 -> 16 bytes.
assert len(loaded["msg"].encode("utf-8")) == 16, loaded["msg"].encode("utf-8")

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "msg:"
validator_assert_contains "$tmpdir/out.yaml" "cjk:"
validator_assert_contains "$tmpdir/out.yaml" $'\xf0\x9f\x8e\x89'
echo "OK"
