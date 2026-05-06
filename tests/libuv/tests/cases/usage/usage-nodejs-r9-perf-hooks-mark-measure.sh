#!/usr/bin/env bash
# @testcase: usage-nodejs-r9-perf-hooks-mark-measure
# @title: Node.js perf_hooks mark and measure
# @description: Records two named marks via perf_hooks.performance and asserts the resulting measure has a non-negative duration and the right name.
# @timeout: 60
# @tags: usage, perf-hooks, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node - <<'JS'
const { performance, PerformanceObserver } = require('perf_hooks');
const assert = require('assert');

const seen = [];
const obs = new PerformanceObserver(items => {
  for (const e of items.getEntries()) seen.push(e);
});
obs.observe({ entryTypes: ['measure'] });

performance.mark('a');
for (let i = 0, x = 0; i < 1000; i++) x += i;
performance.mark('b');
performance.measure('span', 'a', 'b');

setImmediate(() => {
  obs.disconnect();
  assert.equal(seen.length, 1);
  assert.equal(seen[0].name, 'span');
  assert.equal(seen[0].entryType, 'measure');
  assert.ok(seen[0].duration >= 0, `duration ${seen[0].duration}`);
});
JS
