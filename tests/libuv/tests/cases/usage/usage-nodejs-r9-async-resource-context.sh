#!/usr/bin/env bash
# @testcase: usage-nodejs-r9-async-resource-context
# @title: Node.js AsyncResource runInAsyncScope
# @description: Wraps a callback with AsyncResource and verifies runInAsyncScope passes through the supplied this and arguments.
# @timeout: 60
# @tags: usage, async-hooks, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - <<'JS'
const { AsyncResource } = require('async_hooks');
const assert = require('assert');

const res = new AsyncResource('TestScope');
const ctx = { tag: 'ctx-1' };
const result = res.runInAsyncScope(function (a, b) {
  return [this.tag, a + b];
}, ctx, 2, 3);

assert.deepStrictEqual(result, ['ctx-1', 5]);
res.emitDestroy();
JS
