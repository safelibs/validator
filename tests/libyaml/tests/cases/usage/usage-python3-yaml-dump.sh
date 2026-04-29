#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump
# @title: PyYAML dump
# @description: Runs PyYAML dump behavior through libyaml.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
import yaml; print(yaml.safe_dump({'name':'alpha','items':[1,2]}, sort_keys=True))
PY
