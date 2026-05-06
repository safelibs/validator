#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r9-merge-key-anchor
# @title: PyYAML merge key resolves anchored map
# @description: Loads a YAML mapping with a merge key '<<' that pulls fields from an anchored mapping, asserting overrides win and missing keys are inherited.
# @timeout: 60
# @tags: usage, python3-yaml
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PY'
import yaml
text = """defaults: &d
  host: localhost
  port: 8080
  debug: false

server:
  <<: *d
  port: 9000
"""
data = yaml.safe_load(text)
assert data['server']['host'] == 'localhost'
assert data['server']['port'] == 9000
assert data['server']['debug'] is False
PY
