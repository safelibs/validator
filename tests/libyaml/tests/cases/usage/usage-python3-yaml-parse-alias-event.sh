#!/usr/bin/env bash
# @testcase: usage-python3-yaml-parse-alias-event
# @title: PyYAML parse alias event
# @description: Parses YAML events with PyYAML and verifies an alias event is emitted for aliased input.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-parse-alias-event"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' "$case_id" "$tmpdir"
import sys
import yaml
from yaml.events import AliasEvent, MappingStartEvent, ScalarEvent
from yaml.tokens import AliasToken, AnchorToken, ScalarToken

case_id = sys.argv[1]
tmpdir = sys.argv[2]

events = list(yaml.parse("root: &anchor alpha\nref: *anchor\n"))
names = [type(event).__name__ for event in events]
assert any(isinstance(event, MappingStartEvent) for event in events)
assert any(isinstance(event, AliasEvent) and event.anchor == "anchor" for event in events)
scalar_values = [event.value for event in events if isinstance(event, ScalarEvent)]
assert scalar_values == ["root", "alpha", "ref"]
print(",".join(names))
PY
