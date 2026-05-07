#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r13-yamlerror-base-of-constructor-error
# @title: PyYAML ConstructorError and ScannerError both subclass YAMLError
# @description: Imports yaml.constructor.ConstructorError and yaml.scanner.ScannerError and asserts both classes are subclasses of yaml.YAMLError, locking in the exception hierarchy that lets callers catch any parse or build error with a single yaml.YAMLError except clause.
# @timeout: 60
# @tags: usage, python3-yaml, error-hierarchy
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
import yaml.constructor
import yaml.scanner

assert issubclass(yaml.constructor.ConstructorError, yaml.YAMLError), \
    'ConstructorError must be a YAMLError subclass'
assert issubclass(yaml.scanner.ScannerError, yaml.YAMLError), \
    'ScannerError must be a YAMLError subclass'

# A scanner error must actually be catchable as a YAMLError.
try:
    yaml.safe_load('a: [1, 2\n')
except yaml.YAMLError:
    caught_yaml_error = True
else:
    raise SystemExit('expected YAMLError on truncated flow sequence')
assert caught_yaml_error
PY
