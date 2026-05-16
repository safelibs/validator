#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r21-safe-dump-sort-keys-true-orders-mapping-keys
# @title: PyYAML safe_dump sort_keys=True emits a mapping with keys in alphabetical order
# @description: Calls yaml.safe_dump on a dict whose insertion order is not alphabetical with sort_keys=True and asserts the emitted lines list the mapping keys in alphabetical order — pinning python3-yaml's sort_keys knob through libyaml's emitter.
# @timeout: 60
# @tags: usage, python3-yaml, safe-dump, sort-keys, r21
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

# Insertion order: charlie, alpha, bravo
data = {'charlie': 3, 'alpha': 1, 'bravo': 2}
out = yaml.safe_dump(data, sort_keys=True, default_flow_style=False)
lines = [line.split(':', 1)[0] for line in out.splitlines() if line and not line.startswith(' ')]
assert lines == ['alpha', 'bravo', 'charlie'], lines
PY
