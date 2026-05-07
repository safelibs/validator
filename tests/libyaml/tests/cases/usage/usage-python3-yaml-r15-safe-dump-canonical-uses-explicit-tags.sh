#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r15-safe-dump-canonical-uses-explicit-tags
# @title: PyYAML safe_dump canonical=True emits explicit "!!" tag prefixes for scalars
# @description: Dumps a small mapping with safe_dump(canonical=True) and asserts the output contains explicit YAML tag prefixes (!!str, !!int, !!map) and an explicit document start marker "---" — locking in that the SafeDumper canonical mode writes fully tag-explicit YAML on Ubuntu 24.04 PyYAML 6.x. Distinct from the regular Dumper canonical test (r12).
# @timeout: 60
# @tags: usage, python3-yaml, safedump, canonical
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = {'name': 'alice', 'count': 3}
out = yaml.safe_dump(src, canonical=True)
# Canonical mode produces explicit tags and an explicit doc start.
assert '---' in out, out
assert '!!str' in out, out
assert '!!int' in out, out
assert '!!map' in out, out
# The output still loads back to the same dict.
back = yaml.safe_load(out)
assert back == src, (back, src)
PY
