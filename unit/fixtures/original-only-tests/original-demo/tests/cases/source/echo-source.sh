#!/usr/bin/env bash
# @testcase: source-echo-roundtrip
# @title: Source echo round trip
# @description: Runs a small source-facing shell harness against the fixture original package surface.
# @timeout: 300
# @tags: api, smoke

set -euo pipefail

echo "source fixture ran"
test -d /validator/tests/original-demo
