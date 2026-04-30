#!/usr/bin/env bash
# @testcase: usage-python3-yaml-yamlerror-syntax-catch-batch12
# @title: PyYAML YAMLError catches scanner syntax error
# @description: Feeds malformed flow content to yaml.safe_load and verifies the raised exception is caught as yaml.YAMLError with a ScannerError subtype.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-yamlerror-syntax-catch-batch12"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" >"$tmpdir/out"
import sys
import yaml
from yaml.scanner import ScannerError

case_id = sys.argv[1]

malformed = "key: 'unterminated\n"

caught = None
try:
    yaml.safe_load(malformed)
except yaml.YAMLError as exc:
    caught = exc

assert caught is not None, "expected YAMLError to be raised"
assert isinstance(caught, yaml.YAMLError), type(caught).__name__
# PyYAML raises ScannerError for an unterminated single-quoted scalar.
assert isinstance(caught, ScannerError), type(caught).__name__

# The exception carries a context message useful for callers.
msg = str(caught)
assert msg, "YAMLError message must not be empty"

print("EXC_TYPE", type(caught).__name__)
print("IS_YAMLERROR", isinstance(caught, yaml.YAMLError))
print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "EXC_TYPE ScannerError"
validator_assert_contains "$tmpdir/out" "IS_YAMLERROR True"
validator_assert_contains "$tmpdir/out" "OK"
echo "OK"
