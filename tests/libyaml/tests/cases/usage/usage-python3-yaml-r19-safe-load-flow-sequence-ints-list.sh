#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r19-safe-load-flow-sequence-ints-list
# @title: PyYAML safe_load on a single-line flow sequence yields a Python list of ints
# @description: Parses the document 'nums: [4, 8, 15, 16, 23, 42]' via yaml.safe_load and asserts the resulting value is a Python list whose elements are all int and equal to the literal sequence — pinning the libyaml flow-style integer resolver.
# @timeout: 60
# @tags: usage, python3-yaml, flow-sequence, r19
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

data = yaml.safe_load('nums: [4, 8, 15, 16, 23, 42]\n')
nums = data['nums']
assert isinstance(nums, list), type(nums)
assert nums == [4, 8, 15, 16, 23, 42], nums
for n in nums:
    assert isinstance(n, int), (n, type(n))
PY
