#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r10-fullloader-python-tuple-roundtrip
# @title: PyYAML FullLoader resolves !!python/tuple to a Python tuple
# @description: Loads a document with an explicit !!python/tuple tag via yaml.FullLoader and asserts the value is a tuple of three ints, then roundtrips via yaml.dump and reloads to confirm the same tuple shape comes back.
# @timeout: 60
# @tags: usage, python3-yaml, fullloader
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
text = "items: !!python/tuple [1, 2, 3]\n"
data = yaml.load(text, Loader=yaml.FullLoader)
assert isinstance(data['items'], tuple), type(data['items'])
assert data['items'] == (1, 2, 3), data['items']

# Roundtrip via Dumper (not SafeDumper, which rejects tuples) and FullLoader.
dumped = yaml.dump(data, Dumper=yaml.Dumper)
back = yaml.load(dumped, Loader=yaml.FullLoader)
assert isinstance(back['items'], tuple), type(back['items'])
assert back['items'] == (1, 2, 3), back['items']
PY
