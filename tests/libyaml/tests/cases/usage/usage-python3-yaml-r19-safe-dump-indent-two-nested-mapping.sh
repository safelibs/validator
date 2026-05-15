#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r19-safe-dump-indent-two-nested-mapping
# @title: PyYAML safe_dump with indent=2 renders nested mappings with exactly two-space indentation
# @description: Dumps a two-level nested mapping via yaml.safe_dump(indent=2) and asserts the inner key 'k' appears prefixed by exactly two leading spaces — pinning the safe-dump indent emitter setting.
# @timeout: 60
# @tags: usage, python3-yaml, safe-dump, indent, r19
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = {'outer': {'k': 'v'}}
out = yaml.safe_dump(data, indent=2)
lines = out.splitlines()
inner = [line for line in lines if 'k:' in line]
assert len(inner) == 1, lines
# Exactly two spaces of leading indentation before 'k:'.
assert inner[0].startswith('  k:'), repr(inner[0])
assert not inner[0].startswith('   k:'), repr(inner[0])
PY
