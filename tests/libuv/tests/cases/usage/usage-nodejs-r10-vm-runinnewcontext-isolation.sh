#!/usr/bin/env bash
# @testcase: usage-nodejs-r10-vm-runinnewcontext-isolation
# @title: Node.js vm.runInNewContext isolates the global object
# @description: Evaluates code in two independent vm contexts and verifies a name set in one is not visible in the other while a value can still be returned to the calling scope.
# @timeout: 30
# @tags: usage, vm, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

node - <<'JS'
const vm = require('vm');
const assert = require('assert');

const ctxA = { x: 1 };
const ctxB = { x: 2 };

const sumA = vm.runInNewContext('var hidden = 99; x + 10', ctxA);
const sumB = vm.runInNewContext('x + 20', ctxB);

assert.strictEqual(sumA, 11);
assert.strictEqual(sumB, 22);
assert.strictEqual(ctxA.hidden, 99);
assert.strictEqual('hidden' in ctxB, false, 'ctxB must not see ctxA hidden var');
assert.strictEqual(typeof globalThis.hidden, 'undefined', 'host scope must remain clean');
JS
