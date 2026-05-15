#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r19-csafe-dump-width-twenty-wraps
# @title: PyYAML yaml.dump with CSafeDumper and width=20 wraps a long inline string across lines
# @description: Dumps a mapping containing a 60-character ASCII run via yaml.dump using Dumper=yaml.CSafeDumper with width=20, asserts the emitted output is non-empty and spans at least two lines, and that safe_load reads back the original string — pinning the C-backed emitter width knob.
# @timeout: 60
# @tags: usage, python3-yaml, csafe-dumper, width, r19
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

long_text = 'abcdef ' * 12  # ~84 chars total, well above width=20
data = {'k': long_text.strip()}
out = yaml.dump(data, Dumper=yaml.CSafeDumper, width=20)
assert out, 'empty dump'
lines = [l for l in out.splitlines() if l.strip()]
assert len(lines) >= 2, (lines, out)
back = yaml.safe_load(out)
assert back == data, (back, data)
PY
