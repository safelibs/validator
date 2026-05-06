#!/usr/bin/env bash
# @testcase: usage-nodejs-r10-async-local-storage-context
# @title: Node.js AsyncLocalStorage propagates store across awaits
# @description: Runs two concurrent ALS.run scopes, awaits a setImmediate plus a setTimeout chain in each, and asserts each promise resolves to its own scope's store value.
# @timeout: 30
# @tags: usage, async-hooks, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

node - <<'JS'
const { AsyncLocalStorage } = require('async_hooks');
const assert = require('assert');

const als = new AsyncLocalStorage();

async function chain() {
  await new Promise(r => setImmediate(r));
  await new Promise(r => setTimeout(r, 5));
  return als.getStore();
}

(async () => {
  const [a, b] = await Promise.all([
    new Promise(resolve => als.run({ tag: 'alpha' }, () => resolve(chain()))),
    new Promise(resolve => als.run({ tag: 'beta' }, () => resolve(chain()))),
  ]);
  assert.deepStrictEqual(a, { tag: 'alpha' });
  assert.deepStrictEqual(b, { tag: 'beta' });
  // Outside any run() store should be undefined.
  assert.strictEqual(als.getStore(), undefined);
})().catch(e => { console.error(e); process.exit(1); });
JS
