#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r11-scan-block-mapping-end-tokens
# @title: PyYAML scan emits BlockMappingStartToken and BlockEndToken for block mapping
# @description: Tokenises a two-key block mapping via yaml.scan and asserts the token sequence opens with BlockMappingStartToken, closes with BlockEndToken before StreamEndToken, and contains exactly two KeyToken / ValueToken pairs.
# @timeout: 60
# @tags: usage, python3-yaml, scan, tokens
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

names = [type(t).__name__ for t in yaml.scan("a: 1\nb: 2\n")]
assert names[0] == 'StreamStartToken', names
assert names[1] == 'BlockMappingStartToken', names
assert names[-1] == 'StreamEndToken', names
assert names[-2] == 'BlockEndToken', names
assert names.count('KeyToken') == 2, names
assert names.count('ValueToken') == 2, names
assert names.count('ScalarToken') == 4, names  # 2 keys + 2 values
PY
