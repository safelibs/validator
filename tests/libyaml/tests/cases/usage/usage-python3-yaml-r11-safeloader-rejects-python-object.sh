#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r11-safeloader-rejects-python-object
# @title: PyYAML safe_load rejects !!python/object/apply tag
# @description: Confirms yaml.safe_load raises ConstructorError when fed a document containing the !!python/object/apply tag, the canonical CVE-2017-18342 payload shape that pre-5.1 PyYAML deserialised into arbitrary callables.
# @timeout: 60
# @tags: usage, python3-yaml, security, safeloader
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml
payload = '!!python/object/apply:os.system ["echo never_executed"]\n'
try:
    yaml.safe_load(payload)
except yaml.constructor.ConstructorError as exc:
    msg = str(exc)
    assert 'tag:yaml.org,2002:python/object/apply' in msg, msg
    assert 'could not determine a constructor' in msg, msg
else:
    raise SystemExit('safe_load accepted !!python/object/apply payload')
PY
