#!/usr/bin/env bash
# @testcase: usage-nodejs-child-process
# @title: Node.js child process
# @description: Runs Node.js child process behavior to exercise libuv.
# @timeout: 180
# @tags: usage, event-loop
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node -e "require('child_process').execFile('/bin/echo',['child-ok'],(e,out)=>{if(e)throw e; console.log(out.trim());});" "$tmpdir/node.txt"
