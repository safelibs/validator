#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r15-scan-block-end-token-present
# @title: PyYAML scan emits a BlockEndToken closing a block mapping
# @description: Scans the token stream for a small block mapping and asserts a BlockEndToken appears in the stream — locking in the SafeLoader scanner emits an explicit block-end marker for indented block mappings on Ubuntu 24.04 PyYAML 6.x. Distinct from the existing block-mapping-end-tokens batch11 test that asserts a count rather than presence-by-class.
# @timeout: 60
# @tags: usage, python3-yaml, scan, block-end
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "outer:\n  inner: 1\n"
tokens = list(yaml.scan(doc))
names = [type(t).__name__ for t in tokens]
assert 'BlockMappingStartToken' in names, names
assert 'BlockEndToken' in names, names
# The very last token before stream end is StreamEndToken.
assert names[-1] == 'StreamEndToken', names
PY
