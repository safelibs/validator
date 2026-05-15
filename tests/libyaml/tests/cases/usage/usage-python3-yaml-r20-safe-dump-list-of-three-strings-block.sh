#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r20-safe-dump-list-of-three-strings-block
# @title: PyYAML safe_dump on a list of three strings emits three '- ' block-style lines
# @description: Dumps the Python list ['alpha', 'beta', 'gamma'] via yaml.safe_dump with default_flow_style=False and asserts the output contains the lines '- alpha', '- beta', '- gamma' in order — pinning the libyaml emitter's block-sequence dash prefix.
# @timeout: 60
# @tags: usage, python3-yaml, safe-dump, block-sequence, r20
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

out = yaml.safe_dump(['alpha', 'beta', 'gamma'], default_flow_style=False)
lines = [l for l in out.splitlines() if l.strip()]
assert lines == ['- alpha', '- beta', '- gamma'], lines
PY
