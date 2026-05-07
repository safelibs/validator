#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r13-safe-dump-allow-unicode-non-ascii
# @title: PyYAML safe_dump allow_unicode=True writes non-ASCII characters verbatim
# @description: Dumps a string containing CJK, Latin-1, and emoji characters with allow_unicode=True and asserts the output contains the exact UTF-8 codepoints rather than backslash-escape forms, then round-trips through safe_load to confirm the result is byte-identical.
# @timeout: 60
# @tags: usage, python3-yaml, dump, unicode
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = {'greeting': 'naïve 日本語 \U0001F600'}
out = yaml.safe_dump(src, allow_unicode=True)
# Direct codepoints must appear; no \uXXXX escapes.
assert 'naïve' in out, out
assert '日本語' in out, out
assert '\U0001F600' in out, out
assert '\\u' not in out and '\\U' not in out, out
back = yaml.safe_load(out)
assert back == src, (back, src)
PY
