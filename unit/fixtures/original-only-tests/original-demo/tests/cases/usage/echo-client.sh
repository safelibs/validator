#!/usr/bin/env bash
set -euo pipefail

echo "usage fixture ran for demo-client"
test -f /validator/tests/original-demo/tests/fixtures/dependents.json
