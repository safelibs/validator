#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-dump-explicit-end
# @title: PyYAML CSafeDumper explicit end
# @description: Dumps multiple YAML documents with explicit end markers and verifies the terminator appears in the emitted text.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-csafe-dump-explicit-end"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 >"$tmpdir/out" <<'PYCASE'
import yaml
dumper = getattr(yaml, 'CSafeDumper', yaml.SafeDumper)
text = yaml.dump_all([{'a': 1}, {'b': 2}], Dumper=dumper, explicit_end=True)
print(text, end='')
PYCASE
validator_assert_contains "$tmpdir/out" '...'
