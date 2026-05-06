#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r10-csafedumper-default-flow-style-true
# @title: PyYAML CSafeDumper with default_flow_style=True emits flow collections
# @description: Dumps a nested dict via CSafeDumper with default_flow_style=True and asserts the emitted text uses flow-mapping braces and flow-sequence brackets rather than block-style indented form, then reloads via CSafeLoader and confirms equality.
# @timeout: 60
# @tags: usage, python3-yaml, libyaml, flow
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
assert hasattr(yaml, 'CSafeDumper'), 'CSafeDumper missing — libyaml not built'
assert hasattr(yaml, 'CSafeLoader'), 'CSafeLoader missing — libyaml not built'

data = {'name': 'alpha', 'tags': ['x', 'y'], 'meta': {'a': 1, 'b': 2}}
text = yaml.dump(data, Dumper=yaml.CSafeDumper, default_flow_style=True, sort_keys=True)
# Flow style uses braces/brackets and is typically a single line.
assert '{' in text and '}' in text, text
assert '[' in text and ']' in text, text
assert 'name: alpha' in text or "name: 'alpha'" in text or 'name: "alpha"' in text, text

back = yaml.load(text, Loader=yaml.CSafeLoader)
assert back == data, (back, data)
PY
