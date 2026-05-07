#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r14-emit-from-parse-roundtrip
# @title: PyYAML emit consumes events from parse and reproduces a load-equivalent document
# @description: Pipes the event stream produced by yaml.parse on a small mapping directly into yaml.emit and asserts the regenerated YAML text loads back to the same Python dict as the original — exercising the parse/emit pair without going through the constructor or representer.
# @timeout: 60
# @tags: usage, python3-yaml, emit, parse, events
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = "a: 1\nb: 2\n"
events = list(yaml.parse(src))
# parse must emit a StreamStart, DocumentStart, MappingStart, ..., StreamEnd sequence.
names = [type(e).__name__ for e in events]
assert names[0] == 'StreamStartEvent', names
assert names[-1] == 'StreamEndEvent', names
assert 'MappingStartEvent' in names, names
out = yaml.emit(events)
got = yaml.safe_load(out)
assert got == {'a': 1, 'b': 2}, (got, out)
PY
