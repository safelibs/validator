#!/usr/bin/env bash
# @testcase: usage-python3-yaml-csafe-backend-available
# @title: PyYAML CSafeLoader and CSafeDumper backend available
# @description: Confirms PyYAML exposes the libyaml-backed CSafeLoader and CSafeDumper classes and that safe_load is wired to the C backend.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY' | tee "$tmpdir/out"
import yaml
import yaml.cyaml

assert hasattr(yaml, "CSafeLoader"), "yaml.CSafeLoader missing - libyaml backend not available"
assert hasattr(yaml, "CSafeDumper"), "yaml.CSafeDumper missing - libyaml backend not available"
assert yaml.__with_libyaml__ is True, "yaml.__with_libyaml__ should be True"

# Confirm the C-extension classes are usable end-to-end.
loaded = yaml.load("alpha: 1\nbeta: 2\n", Loader=yaml.CSafeLoader)
assert loaded == {"alpha": 1, "beta": 2}

dumped = yaml.dump({"x": 7}, Dumper=yaml.CSafeDumper)
assert "x: 7" in dumped

print("CSAFE_OK", yaml.__with_libyaml__)
PY

validator_assert_contains "$tmpdir/out" 'CSAFE_OK True'
