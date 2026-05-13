#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r16-add-representer-tuple-as-flow-sequence
# @title: PyYAML SafeDumper.add_representer for tuple emits a flow-style sequence
# @description: Registers a SafeDumper representer that maps Python tuple to a flow-style YAML sequence, dumps a small tuple via yaml.safe_dump, and asserts the output contains the flow-sequence form '[a, b, c]' rather than the block-style hyphen list.
# @timeout: 60
# @tags: usage, python3-yaml, representer, tuple
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

def tuple_repr(dumper, data):
    return dumper.represent_sequence(
        'tag:yaml.org,2002:seq', list(data), flow_style=True
    )

yaml.SafeDumper.add_representer(tuple, tuple_repr)
text = yaml.safe_dump({'items': ('alpha', 'bravo', 'charlie')}).strip()

# Expect a flow-style sequence, not a block-style one.
assert '[alpha, bravo, charlie]' in text, text
# No leading '- ' line for the sequence entries.
for line in text.splitlines():
    if line.lstrip().startswith('- '):
        raise AssertionError(('unexpected block-style line', line, text))
PY
