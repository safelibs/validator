#!/usr/bin/env bash
# @testcase: usage-python3-yaml-events
# @title: PyYAML events
# @description: Runs PyYAML events behavior through libyaml.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
import yaml; events=list(yaml.parse('name: alpha\n')); print(len(events))
PY
