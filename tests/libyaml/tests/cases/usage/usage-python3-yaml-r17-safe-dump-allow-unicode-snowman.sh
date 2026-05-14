#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r17-safe-dump-allow-unicode-snowman
# @title: PyYAML safe_dump allow_unicode=True emits a literal snowman character
# @description: Dumps a mapping containing the U+2603 snowman character with yaml.safe_dump(allow_unicode=True), captures the output, and asserts the literal snowman character appears in the serialized text rather than being escaped to an ASCII escape sequence.
# @timeout: 60
# @tags: usage, python3-yaml, unicode
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
text = yaml.safe_dump({'icon': '☃ snow'}, allow_unicode=True)
assert '☃' in text, repr(text)
# And it round-trips back as the same string.
out = yaml.safe_load(text)
assert out == {'icon': '☃ snow'}, out
PY
