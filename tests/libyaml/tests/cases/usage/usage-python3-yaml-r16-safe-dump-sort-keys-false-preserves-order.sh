#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r16-safe-dump-sort-keys-false-preserves-order
# @title: PyYAML safe_dump sort_keys=False preserves the source mapping's insertion order
# @description: Dumps an ordered dict-style mapping with sort_keys=False and asserts the emitted lines appear in the original insertion order (zebra, apple, mango) — not alphabetical (the sort_keys=True default).
# @timeout: 60
# @tags: usage, python3-yaml, safedump, sort
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = {'zebra': 1, 'apple': 2, 'mango': 3}
text = yaml.safe_dump(src, sort_keys=False, default_flow_style=False)
lines = [l for l in text.rstrip('\n').splitlines() if ':' in l]
keys = [l.split(':', 1)[0] for l in lines]
assert keys == ['zebra', 'apple', 'mango'], keys

# And with sort_keys defaulting to True, order would be alphabetical:
sorted_text = yaml.safe_dump(src, default_flow_style=False)
sorted_keys = [l.split(':', 1)[0]
               for l in sorted_text.rstrip('\n').splitlines() if ':' in l]
assert sorted_keys == ['apple', 'mango', 'zebra'], sorted_keys
PY
