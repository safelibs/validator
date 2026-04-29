#!/usr/bin/env bash
# @testcase: usage-nodejs-readline-async-iterator-batch11
# @title: Node.js readline async iterator
# @description: Reads stream lines through Node.js readline async iteration.
# @timeout: 180
# @tags: usage, nodejs, libuv
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-nodejs-readline-async-iterator-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const readline = require('readline');
const { Readable } = require('stream');
(async () => {
  const rl = readline.createInterface({ input: Readable.from(['alpha\n', 'beta\n']) });
  const rows = [];
  for await (const line of rl) rows.push(line);
  console.log(rows.join(','));
})().catch(err => { console.error(err); process.exit(1); });
JS
validator_assert_contains "$tmpdir/out" 'alpha,beta'
