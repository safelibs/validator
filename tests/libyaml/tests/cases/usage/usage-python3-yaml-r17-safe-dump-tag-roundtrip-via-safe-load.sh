#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r17-safe-dump-tag-roundtrip-via-safe-load
# @title: PyYAML safe_dump output of plain types round-trips byte-for-byte through safe_load
# @description: Dumps a heterogeneous container of plain types (int, str, bool, None, nested list+dict) via yaml.safe_dump, parses the result back with yaml.safe_load, and asserts the structure matches the original — pinning the safe loader/dumper inverse contract.
# @timeout: 60
# @tags: usage, python3-yaml, roundtrip
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = {
    'i': 42,
    's': 'hello',
    'b': True,
    'n': None,
    'l': [1, 2, {'k': 'v'}],
}
text = yaml.safe_dump(src)
back = yaml.safe_load(text)
assert back == src, (back, src)
PY
