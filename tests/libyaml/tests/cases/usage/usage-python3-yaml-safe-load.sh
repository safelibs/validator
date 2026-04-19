#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    python3 - <<'PY'
import yaml; data=yaml.safe_load('name: alpha\nitems:\n - one\n'); print(data['name'], len(data['items']))
PY