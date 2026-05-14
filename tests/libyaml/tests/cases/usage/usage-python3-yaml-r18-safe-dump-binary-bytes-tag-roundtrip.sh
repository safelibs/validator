#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r18-safe-dump-binary-bytes-tag-roundtrip
# @title: PyYAML safe_dump emits non-ASCII bytes with !!binary tag and safe_load decodes back
# @description: Dumps a Python bytes object containing non-ASCII bytes via yaml.safe_dump, verifies the rendered YAML carries an !!binary tag marker, and asserts yaml.safe_load reconstructs the original bytes exactly.
# @timeout: 60
# @tags: usage, python3-yaml, safe-dump, binary, r18
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

payload = bytes(range(0, 32)) + b'\x80\x81\xfe\xff'
out = yaml.safe_dump({'b': payload})
assert '!!binary' in out, out
reloaded = yaml.safe_load(out)
assert reloaded['b'] == payload, (reloaded['b'], payload)
PY
