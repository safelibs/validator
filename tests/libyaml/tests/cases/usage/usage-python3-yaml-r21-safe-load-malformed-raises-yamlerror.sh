#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r21-safe-load-malformed-raises-yamlerror
# @title: PyYAML safe_load on malformed YAML raises yaml.YAMLError
# @description: Feeds a syntactically malformed flow sequence (unbalanced brackets) to yaml.safe_load and asserts the resulting exception is an instance of yaml.YAMLError — pinning libyaml's error-path surfaced as YAMLError through python3-yaml.
# @timeout: 60
# @tags: usage, python3-yaml, safe-load, error-path, r21
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

bad = '[a, b, c'
try:
    yaml.safe_load(bad)
except yaml.YAMLError:
    raised = True
else:
    raised = False
assert raised, "expected yaml.YAMLError on malformed flow sequence"
PY
