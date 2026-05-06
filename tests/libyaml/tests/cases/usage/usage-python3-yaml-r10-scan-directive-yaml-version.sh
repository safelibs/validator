#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r10-scan-directive-yaml-version
# @title: PyYAML yaml.scan emits DirectiveToken for %YAML 1.1
# @description: Scans a document beginning with %YAML 1.1 and asserts the emitted token stream contains a DirectiveToken whose name attribute is 'YAML' and whose value is the (1, 1) tuple.
# @timeout: 60
# @tags: usage, python3-yaml, scanner
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
from yaml.tokens import DirectiveToken

text = "%YAML 1.1\n---\nfoo: bar\n"
tokens = list(yaml.scan(text))
directives = [t for t in tokens if isinstance(t, DirectiveToken)]
assert len(directives) == 1, [type(t).__name__ for t in tokens]
d = directives[0]
assert d.name == 'YAML', d.name
assert tuple(d.value) == (1, 1), d.value
PY
