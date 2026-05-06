#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r11-safe-load-int-with-underscores
# @title: PyYAML safe_load parses 1_000_000 as Python int 1000000
# @description: Loads a document with the YAML 1.1 underscore-delimited integer literal 1_000_000 and asserts safe_load returns the int 1000000, confirming the digit-grouping syntax round-trips through the SafeLoader's implicit int resolver.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, int
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = yaml.safe_load("amount: 1_000_000\n")
assert isinstance(data['amount'], int), type(data['amount'])
assert data['amount'] == 1_000_000, data['amount']
PY
