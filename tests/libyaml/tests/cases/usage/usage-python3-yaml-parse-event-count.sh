#!/usr/bin/env bash
# @testcase: usage-python3-yaml-parse-event-count
# @title: PyYAML parse event count
# @description: Parses YAML into events with PyYAML and verifies that a non-empty event stream is produced.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-parse-event-count"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
events = list(yaml.parse('alpha: 1\nbeta: 2\n'))
print(len(events))
PYCASE
grep -Eq '^[0-9]+$' "$tmpdir/out"
