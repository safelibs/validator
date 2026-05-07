#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r15-safe-dump-default-style-pipe-literal
# @title: PyYAML safe_dump default_style="|" emits literal-block-scalar style for strings
# @description: Dumps a multiline string under safe_dump(default_style="|") and asserts the output uses the literal block scalar style (a leading "|" indicator on the value line) rather than quoted or plain — locking in the SafeDumper literal-style explicit-default path on Ubuntu 24.04 PyYAML 6.x. Distinct from the double- and single-quoted default_style tests already covered.
# @timeout: 60
# @tags: usage, python3-yaml, safedump, default-style, literal
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = {'note': 'first line\nsecond line\n'}
out = yaml.safe_dump(src, default_style='|')
# A literal-block-scalar style places the "|" indicator after the key's colon.
assert ': |' in out, out
# The body lines must appear verbatim in the dumped output.
assert 'first line' in out, out
assert 'second line' in out, out
back = yaml.safe_load(out)
assert back == src, (back, src)
PY
