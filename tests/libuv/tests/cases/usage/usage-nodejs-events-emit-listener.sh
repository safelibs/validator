#!/usr/bin/env bash
# @testcase: usage-nodejs-events-emit-listener
# @title: nodejs events emit listener
# @description: Registers an EventEmitter listener and verifies the callback receives the emitted argument value.
# @timeout: 180
# @tags: usage, nodejs, events
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-events-emit-listener"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const { EventEmitter } = require('events');
const e = new EventEmitter();
e.on('hello', (m) => console.log('got:' + m));
e.emit('hello', 'world');
JS
validator_assert_contains "$tmpdir/out" 'got:world'
