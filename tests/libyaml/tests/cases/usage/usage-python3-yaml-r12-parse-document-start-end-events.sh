#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r12-parse-document-start-end-events
# @title: PyYAML parse emits one DocumentStartEvent and DocumentEndEvent per document
# @description: Parses a three-document YAML stream and asserts the event stream contains exactly three DocumentStartEvent and three DocumentEndEvent occurrences flanked by a single StreamStart/StreamEnd pair.
# @timeout: 60
# @tags: usage, python3-yaml, parse, events
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "a: 1\n---\nb: 2\n---\nc: 3\n"
names = [type(e).__name__ for e in yaml.parse(doc)]
assert names[0] == 'StreamStartEvent', names
assert names[-1] == 'StreamEndEvent', names
assert names.count('DocumentStartEvent') == 3, names
assert names.count('DocumentEndEvent') == 3, names
PY
