#!/usr/bin/env bash
# @testcase: usage-python3-yaml-dump-version-directive-batch13
# @title: PyYAML dump with %YAML 1.2 version directive
# @description: Dumps a mapping with yaml.dump and version=(1, 2) and verifies the %YAML 1.2 directive is emitted in the output stream.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-dump-version-directive-batch13"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out.yaml"
import sys
import yaml

case_id = sys.argv[1]
dst = sys.argv[2]

data = {"alpha": 1, "beta": 2}
text = yaml.dump(data, version=(1, 2), default_flow_style=False, sort_keys=True)

assert "%YAML 1.2" in text, text
assert "alpha" in text and "beta" in text, text

with open(dst, "w", encoding="utf-8") as fh:
    fh.write(text)

loaded = yaml.safe_load(text)
assert loaded == data, loaded
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out.yaml" "%YAML 1.2"
validator_assert_contains "$tmpdir/out.yaml" "alpha"
echo "OK"
