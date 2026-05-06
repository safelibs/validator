#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r11-safe-dump-tuple-as-block-sequence
# @title: PyYAML safe_dump represents a Python tuple as a block sequence
# @description: Calls yaml.safe_dump on a 3-tuple and asserts the output is the canonical block sequence "- 1\n- 2\n- 3\n" — confirming SafeDumper falls back to the list representer for tuples instead of emitting a !!python/tuple tag.
# @timeout: 60
# @tags: usage, python3-yaml, safedumper, tuple
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

out = yaml.safe_dump((1, 2, 3))
assert out == '- 1\n- 2\n- 3\n', repr(out)
back = yaml.safe_load(out)
assert back == [1, 2, 3], back
assert isinstance(back, list), type(back)  # round-trips through SafeLoader as list, not tuple
PY
