#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r12-dump-canonical-explicit-tags
# @title: PyYAML safe_dump canonical=True emits explicit !!str / !!int tags
# @description: Dumps a small mapping with canonical=True and asserts the canonical form embeds explicit !!str and !!int tag URIs, distinguishing canonical output from compact safe_dump default output.
# @timeout: 60
# @tags: usage, python3-yaml, dump, canonical
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = {'name': 'alpha', 'count': 7}
out = yaml.safe_dump(src, canonical=True)
assert '!!str' in out, out
assert '!!int' in out, out
# Canonical form opens with a YAML directive and explicit document start
assert '%YAML' in out or '---' in out, out
back = yaml.safe_load(out)
assert back == src, (back, src)
PY
