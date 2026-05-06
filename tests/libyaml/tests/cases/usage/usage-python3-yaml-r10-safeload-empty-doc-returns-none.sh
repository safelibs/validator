#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r10-safeload-empty-doc-returns-none
# @title: PyYAML safe_load of empty / whitespace / comment-only inputs returns None
# @description: Calls yaml.safe_load on the empty string, a whitespace-only string, a comment-only string, and an explicit document marker with no content, asserting each returns Python None rather than raising or returning an empty container.
# @timeout: 60
# @tags: usage, python3-yaml, edge
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
for label, text in [
    ('empty', ''),
    ('whitespace', '   \n  \n'),
    ('comment-only', '# just a comment\n# another line\n'),
    ('explicit-empty-doc', '---\n'),
]:
    result = yaml.safe_load(text)
    assert result is None, (label, repr(result))
PY
