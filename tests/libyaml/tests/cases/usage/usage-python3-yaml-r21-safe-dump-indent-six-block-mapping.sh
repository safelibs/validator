#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r21-safe-dump-indent-six-block-mapping
# @title: PyYAML safe_dump indent=6 emits a nested block mapping indented by six spaces
# @description: Calls yaml.safe_dump on a nested dict with indent=6 and default_flow_style=False and asserts the inner mapping line begins with at least six spaces — pinning libyaml's emitter indent control through python3-yaml.
# @timeout: 60
# @tags: usage, python3-yaml, safe-dump, indent, block, r21
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = {'outer': {'inner': 42}}
out = yaml.safe_dump(data, indent=6, default_flow_style=False)
lines = out.splitlines()
# Find the inner line: starts with whitespace and contains 'inner:'
inner = next(line for line in lines if line.lstrip().startswith('inner:'))
leading = len(inner) - len(inner.lstrip(' '))
assert leading == 6, (leading, repr(inner), out)
PY
