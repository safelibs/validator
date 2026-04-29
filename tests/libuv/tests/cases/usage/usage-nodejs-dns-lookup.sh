#!/usr/bin/env bash
# @testcase: usage-nodejs-dns-lookup
# @title: Node.js dns lookup
# @description: Runs Node.js dns lookup behavior to exercise libuv.
# @timeout: 180
# @tags: usage, event-loop
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node -e "require('dns').lookup('localhost',(e,a)=>{if(e)throw e; console.log('address='+a);});" "$tmpdir/node.txt"
