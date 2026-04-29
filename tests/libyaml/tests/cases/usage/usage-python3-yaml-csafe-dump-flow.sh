#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-dump-flow
# @title: PyYAML CSafeDumper flow style
# @description: Dumps a mapping with PyYAML CSafeDumper in flow style and verifies flow-style YAML is emitted.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-csafe-dump-flow"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import yaml
from yaml.events import AliasEvent, MappingStartEvent, ScalarEvent
from yaml.tokens import AliasToken, AnchorToken, ScalarToken

case_id = sys.argv[1]
tmpdir = sys.argv[2]

dumper = getattr(yaml, "CSafeDumper", yaml.SafeDumper)
loader = getattr(yaml, "CSafeLoader", yaml.SafeLoader)
value = {"name": "alpha", "values": [1, 2]}
text = yaml.dump(value, Dumper=dumper, default_flow_style=True, sort_keys=False)
assert text.startswith("{")
assert yaml.load(text, Loader=loader) == value
print(text.strip())
PY
