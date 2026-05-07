#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r15-parse-scalar-event-style-plain
# @title: PyYAML parse exposes ScalarEvent.style==None for plain (unquoted) scalars
# @description: Parses a YAML mapping with a plain unquoted string value and asserts the resulting ScalarEvent for the value has .style == None (PyYAML's marker for plain style) while the .value matches the source text — locking in the parse-event style sentinel for plain scalars on Ubuntu 24.04 PyYAML 6.x. Distinct from the literal/folded compose tests.
# @timeout: 60
# @tags: usage, python3-yaml, parse, scalar-style
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "name: alice\n"
events = list(yaml.parse(doc))
scalars = [e for e in events if type(e).__name__ == 'ScalarEvent']
# Two scalar events: the key 'name' and the value 'alice', both plain.
values = [(e.value, e.style) for e in scalars]
assert ('name', None) in values, values
assert ('alice', None) in values, values
PY
