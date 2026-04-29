#!/usr/bin/env bash
# @testcase: usage-nodejs-stream-pipe
# @title: Node.js stream pipe
# @description: Runs Node.js stream pipe behavior to exercise libuv.
# @timeout: 180
# @tags: usage, event-loop
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node -e "const {Readable}=require('stream'); Readable.from(['stream-ok']).on('data',d=>console.log(d.toString()));" "$tmpdir/node.txt"
