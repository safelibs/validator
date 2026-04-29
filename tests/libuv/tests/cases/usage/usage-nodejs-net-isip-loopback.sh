#!/usr/bin/env bash
# @testcase: usage-nodejs-net-isip-loopback
# @title: Node.js net isIP
# @description: Validates the loopback literal with Node.js net.isIP and verifies the API reports an IPv4 address.
# @timeout: 180
# @tags: usage, nodejs, network
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-net-isip-loopback"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const net = require('net');
console.log(net.isIP('127.0.0.1'));
JS
validator_assert_contains "$tmpdir/out" '4'
