#!/usr/bin/env bash
# @testcase: usage-python3-yaml-scan-mapping-start-token-count-batch16
# @title: PyYAML yaml.scan emits the expected count of BlockMappingStartTokens
# @description: Scans a YAML document containing exactly three nested block mappings with yaml.scan and verifies the token stream contains exactly three BlockMappingStartToken instances and at least one StreamStartToken / StreamEndToken pair.
# @timeout: 180
# @tags: usage, yaml, python
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-scan-mapping-start-token-count-batch16"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" "$tmpdir/out"
import sys
import yaml
from yaml.tokens import (
    BlockMappingStartToken,
    BlockEndToken,
    StreamStartToken,
    StreamEndToken,
)

case_id = sys.argv[1]
out_path = sys.argv[2]

# Three block mappings: top-level, inner, and innermost.
doc = (
    "outer:\n"
    "  middle:\n"
    "    leaf: 1\n"
)

tokens = list(yaml.scan(doc))

mapping_starts = [t for t in tokens if isinstance(t, BlockMappingStartToken)]
block_ends = [t for t in tokens if isinstance(t, BlockEndToken)]
stream_starts = [t for t in tokens if isinstance(t, StreamStartToken)]
stream_ends = [t for t in tokens if isinstance(t, StreamEndToken)]

assert len(mapping_starts) == 3, [type(t).__name__ for t in tokens]
# Every BlockMappingStartToken must be balanced by a BlockEndToken.
assert len(block_ends) == 3, [type(t).__name__ for t in tokens]
assert len(stream_starts) == 1, len(stream_starts)
assert len(stream_ends) == 1, len(stream_ends)

with open(out_path, "w", encoding="utf-8") as fh:
    fh.write(f"mapping_starts={len(mapping_starts)}\n")
    fh.write(f"block_ends={len(block_ends)}\n")
    fh.write(f"total_tokens={len(tokens)}\n")

print("OK")
PYCASE

validator_assert_contains "$tmpdir/out" "mapping_starts=3"
validator_assert_contains "$tmpdir/out" "block_ends=3"
echo "OK"
