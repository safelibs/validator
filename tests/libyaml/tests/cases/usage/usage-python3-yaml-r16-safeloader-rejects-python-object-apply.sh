#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r16-safeloader-rejects-python-object-apply
# @title: PyYAML SafeLoader raises ConstructorError when given an !!python/object/apply directive
# @description: Calls yaml.safe_load on a document containing a !!python/object/apply tag and asserts a yaml.constructor.ConstructorError is raised, locking in the SafeLoader's refusal to materialize arbitrary Python objects on PyYAML 6.x.
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, security
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

doc = "!!python/object/apply:os.system [echo unsafe]\n"
try:
    yaml.safe_load(doc)
except yaml.constructor.ConstructorError as exc:
    msg = str(exc)
    assert 'python/object' in msg or 'could not determine' in msg.lower() or 'tag' in msg.lower(), msg
else:
    raise AssertionError('expected ConstructorError on python/object/apply under SafeLoader')
PY
