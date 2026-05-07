#!/usr/bin/env bash
# @testcase: usage-python3-yaml-r15-safe-load-all-empty-stream-yields-no-docs
# @title: PyYAML safe_load_all on a fully empty stream produces zero documents
# @description: Calls safe_load_all on an empty string and asserts the materialised list contains zero documents — locking in that the SafeLoader treats a stream with no document tokens as zero-document on Ubuntu 24.04 PyYAML 6.x, distinct from safe_load on an empty doc (which returns None).
# @timeout: 60
# @tags: usage, python3-yaml, safeloader, empty-stream
# @client: python3-yaml

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

python3 - <<'PY'
import yaml

docs = list(yaml.safe_load_all(""))
assert docs == [], docs

# Sanity: a single empty document still produces None via safe_load.
assert yaml.safe_load("") is None
PY
