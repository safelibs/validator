#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r13-omap-tag-list-of-pairs
# @title: PyYAML safe_load !!omap returns a list of (key, value) tuples in declared order
# @description: Loads a sequence tagged with !!omap whose elements are single-key mappings and asserts safe_load yields a Python list of (key, value) tuples preserving the declared order, exercising the SafeConstructor !!omap handler that flattens omap entries into 2-tuples.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, omap
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "ordered: !!omap\n  - first: 1\n  - second: 2\n  - third: 3\n"
data = yaml.safe_load(doc)
ordered = data['ordered']
assert isinstance(ordered, list), type(ordered)
assert len(ordered) == 3, ordered
# Each element is a (key, value) tuple, in declared order.
assert ordered == [('first', 1), ('second', 2), ('third', 3)], ordered
for elem in ordered:
    assert isinstance(elem, tuple) and len(elem) == 2, elem
PY
