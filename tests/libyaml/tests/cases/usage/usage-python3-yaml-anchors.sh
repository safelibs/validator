#!/usr/bin/env bash
# @testcase: usage-python3-yaml-anchors
# @title: PyYAML anchors
# @description: Runs PyYAML anchors behavior through libyaml.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
import yaml; data=yaml.safe_load('base: &b {name: alpha}\ncopy: *b\n'); print(data['copy']['name'])
PY
