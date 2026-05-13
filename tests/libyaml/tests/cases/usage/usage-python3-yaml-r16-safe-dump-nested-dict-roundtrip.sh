#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r16-safe-dump-nested-dict-roundtrip
# @title: PyYAML safe_dump + safe_load preserves a nested dict structure byte-equal to the source mapping
# @description: Serializes a three-level nested dict with mixed scalar types via yaml.safe_dump and reloads it with yaml.safe_load, then asserts the reloaded object equals the original — covering the canonical safe round-trip path on PyYAML 6.x.
# @timeout: 60
# @tags: usage, python3-yaml, safedump, roundtrip
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = {
    'top': {
        'middle': {
            'leaf_str': 'value',
            'leaf_int': 42,
            'leaf_list': [1, 2, 3],
            'leaf_bool': True,
        },
        'sibling': None,
    },
    'second_top': ['a', 'b'],
}

text = yaml.safe_dump(src)
assert isinstance(text, str) and text, repr(text)

loaded = yaml.safe_load(text)
assert loaded == src, (loaded, src)
PY
