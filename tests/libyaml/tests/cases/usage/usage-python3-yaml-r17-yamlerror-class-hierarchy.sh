#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r17-yamlerror-class-hierarchy
# @title: PyYAML scanner/parser errors share the yaml.YAMLError base class
# @description: Invokes yaml.safe_load on a malformed document containing an unclosed flow-style mapping, captures the raised exception, and asserts the exception is an instance of yaml.YAMLError — pinning the public exception hierarchy contract.
# @timeout: 60
# @tags: usage, python3-yaml, error, hierarchy
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

bad = "{a: 1, b: 2\n"  # unclosed flow mapping
try:
    yaml.safe_load(bad)
except yaml.YAMLError as e:
    print('got', type(e).__name__)
else:
    raise AssertionError('expected yaml.YAMLError on malformed input')
PY
