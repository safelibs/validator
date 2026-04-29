#!/usr/bin/env bash
# @testcase: usage-nodejs-stat-call
# @title: Node.js stat call
# @description: Runs Node.js stat call behavior to exercise libuv.
# @timeout: 180
# @tags: usage, event-loop
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node -e "const fs=require('fs'); fs.writeFileSync(process.argv[1],'watch'); fs.stat(process.argv[1],(e,s)=>{if(e)throw e; console.log('size='+s.size);});" "$tmpdir/node.txt"
