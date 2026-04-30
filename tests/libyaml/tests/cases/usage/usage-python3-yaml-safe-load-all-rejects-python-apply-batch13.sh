#!/usr/bin/env bash
# @testcase: usage-python3-yaml-safe-load-all-rejects-python-apply-batch13
# @title: PyYAML SafeLoader rejects !!python/object/apply in load_all
# @description: Feeds a multi-document stream containing a !!python/object/apply tag into yaml.load_all with SafeLoader and verifies a ConstructorError is raised before any unsafe object is constructed.
# @timeout: 180
# @tags: usage, yaml, python, security
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-python3-yaml-safe-load-all-rejects-python-apply-batch13"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

python3 - <<'PYCASE' "$case_id" | tee "$tmpdir/out"
import sys
import yaml
from yaml.constructor import ConstructorError

case_id = sys.argv[1]

stream = (
    "first: ok\n"
    "---\n"
    "evil: !!python/object/apply:os.system [\"echo pwned\"]\n"
)

try:
    list(yaml.load_all(stream, Loader=yaml.SafeLoader))
except ConstructorError as exc:
    msg = str(exc)
    assert "python/object/apply" in msg or "could not determine a constructor" in msg, msg
    print("REJECTED", "python/object/apply" in msg or "constructor" in msg)
    print("OK")
else:
    raise SystemExit("SafeLoader load_all unexpectedly accepted python/object/apply")
PYCASE

validator_assert_contains "$tmpdir/out" "REJECTED True"
validator_assert_contains "$tmpdir/out" "OK"
echo "OK"
