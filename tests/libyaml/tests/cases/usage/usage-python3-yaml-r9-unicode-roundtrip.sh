#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r9-unicode-roundtrip
# @title: PyYAML preserves Unicode strings in roundtrip
# @description: Dumps a dict containing multi-byte Unicode strings with allow_unicode=True and reloads, asserting equality and that the dumped text contains the literal characters.
# @timeout: 60
# @tags: usage, python3-yaml, unicode
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import yaml
data = {'greeting': 'héllo', 'kanji': '日本語', 'emoji': 'sparkle '}
text = yaml.safe_dump(data, allow_unicode=True, sort_keys=True)
assert 'héllo' in text, text
assert '日本語' in text, text
back = yaml.safe_load(text)
assert back == data, (back, data)
PY
