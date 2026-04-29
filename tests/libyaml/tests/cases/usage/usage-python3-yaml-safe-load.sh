#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load
# @title: PyYAML safe load
# @description: Runs PyYAML safe load behavior through libyaml.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
import yaml; data=yaml.safe_load('name: alpha\nitems:\n - one\n'); print(data['name'], len(data['items']))
PY
