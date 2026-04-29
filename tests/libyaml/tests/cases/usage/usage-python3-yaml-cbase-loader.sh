#!/usr/bin/env bash
# @testcase: usage-python3-yaml-cbase-loader
# @title: PyYAML CBaseLoader scalar parsing
# @description: Runs PyYAML CBaseLoader on nested YAML and verifies BaseLoader string scalar behavior.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
import yaml

assert yaml.__with_libyaml__ is True
data = yaml.load(
    """
root:
  enabled: true
  count: 42
  nested:
    label: alpha
""",
    Loader=yaml.CBaseLoader,
)
assert data["root"]["enabled"] == "true"
assert data["root"]["count"] == "42"
assert data["root"]["nested"]["label"] == "alpha"
print(data["root"]["nested"]["label"])
PY

validator_assert_contains "$tmpdir/out" 'alpha'
