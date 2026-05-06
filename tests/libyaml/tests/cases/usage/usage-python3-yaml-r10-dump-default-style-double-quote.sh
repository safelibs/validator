#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r10-dump-default-style-double-quote
# @title: PyYAML yaml.dump default_style='"' wraps scalars in double quotes
# @description: Dumps a mapping of strings with default_style='"' and asserts every value scalar in the output is enclosed in double quotes, then reloads via SafeLoader and confirms equality with the source dict.
# @timeout: 60
# @tags: usage, python3-yaml, dump-style
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
data = {'name': 'alpha', 'kind': 'beta', 'note': 'gamma'}
text = yaml.safe_dump(data, default_style='"', default_flow_style=False, sort_keys=True)
for value in data.values():
    assert f'"{value}"' in text, (value, text)
back = yaml.safe_load(text)
assert back == data, (back, data)
PY
