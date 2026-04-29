#!/usr/bin/env bash
# @testcase: usage-python3-yaml-error
# @title: PyYAML error
# @description: Runs PyYAML error behavior through libyaml.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
import yaml
try:
    yaml.safe_load('name: [unterminated\n')
except yaml.YAMLError as exc:
    print(type(exc).__name__)
else:
    raise SystemExit(1)
PY
