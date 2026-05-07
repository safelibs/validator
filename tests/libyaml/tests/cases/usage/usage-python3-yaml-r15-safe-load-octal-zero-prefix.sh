#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r15-safe-load-octal-zero-prefix
# @title: PyYAML safe_load YAML 1.1 octal "0o17" stays a string under the int resolver
# @description: Loads a scalar written in the YAML 1.2 "0o" octal style and asserts safe_load returns the literal Python string "0o17" — locking in that PyYAML 6.x's SafeLoader int resolver matches YAML 1.1 octals (leading "0") and does NOT match the "0o"-prefixed YAML 1.2 form on Ubuntu 24.04. Distinct from the existing "017" YAML 1.1 octal test which decodes to int 15.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, octal, yaml11
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

# YAML 1.2 "0o17" is NOT recognised by PyYAML 6.x's int resolver (which is
# tuned for YAML 1.1 syntax). It must come back as the literal string.
data = yaml.safe_load("value: 0o17\n")
v = data['value']
assert isinstance(v, str), (v, type(v))
assert v == '0o17', v
# Sanity: the YAML 1.1 form (leading "0") is still resolved to int 15.
assert yaml.safe_load("value: 017\n")['value'] == 15
PY
