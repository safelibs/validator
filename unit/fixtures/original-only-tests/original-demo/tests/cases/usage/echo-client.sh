#!/usr/bin/env bash
# @testcase: usage-client-echo
# @title: Client echo smoke
# @description: Runs a dependent client fixture that is declared in the dependent application inventory.
# @timeout: 300
# @tags: client
# @client: demo-client

set -euo pipefail

echo "usage fixture ran for demo-client"
test -f /validator/tests/original-demo/tests/fixtures/dependents.json
