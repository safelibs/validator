#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r15-safe-dump-width-narrow-wraps-long-string
# @title: PyYAML safe_dump width=20 wraps a long single string across multiple lines
# @description: Dumps a single long string scalar (well over the requested width) under safe_dump(width=20) and asserts the output spans at least 3 lines — locking in that the SafeDumper honours the narrow width hint by folding long scalars on Ubuntu 24.04 PyYAML 6.x. Loading the output reconstructs the original string.
# @timeout: 60
# @tags: usage, python3-yaml, safedump, width
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

src = "alpha beta gamma delta epsilon zeta eta theta iota kappa lambda mu"
out = yaml.safe_dump(src, width=20)
# A long scalar dumped at width=20 must wrap into more than 2 lines.
assert out.count('\n') >= 3, out
back = yaml.safe_load(out)
assert back == src, (back, src)
PY
