#!/usr/bin/env bash
# @testcase: usage-nodejs-event-loop-timer
# @title: Node.js event loop timer
# @description: Runs Node.js event loop timer behavior to exercise libuv.
# @timeout: 180
# @tags: usage, event-loop
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node -e "setTimeout(()=>console.log('timer-fired'),10);" "$tmpdir/node.txt"
