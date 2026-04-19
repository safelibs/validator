#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
import yaml; data=yaml.safe_load('base: &b {name: alpha}\ncopy: *b\n'); print(data['copy']['name'])
PY