#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r10-dump-encoding-utf8-bytes
# @title: PyYAML yaml.dump with encoding='utf-8' returns bytes
# @description: Calls yaml.safe_dump with encoding='utf-8' on a dict containing non-ASCII characters and asserts the return value is bytes whose UTF-8 decoding contains the original characters and reloads to the source dict.
# @timeout: 60
# @tags: usage, python3-yaml, encoding
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
data = {'greeting': 'héllo', 'kanji': '日本語'}
encoded = yaml.safe_dump(data, encoding='utf-8', allow_unicode=True, sort_keys=True)
assert isinstance(encoded, bytes), type(encoded)
text = encoded.decode('utf-8')
assert 'héllo' in text, text
assert '日本語' in text, text
back = yaml.safe_load(encoded)
assert back == data, (back, data)
PY
