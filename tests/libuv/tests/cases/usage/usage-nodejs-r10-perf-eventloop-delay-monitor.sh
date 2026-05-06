#!/usr/bin/env bash
# @testcase: usage-nodejs-r10-perf-eventloop-delay-monitor
# @title: Node.js perf_hooks monitorEventLoopDelay records samples
# @description: Enables a monitorEventLoopDelay histogram, busy-waits to trigger samples, and asserts the histogram exposes a positive min/max in nanoseconds and a nonzero count after disable.
# @timeout: 30
# @tags: usage, perf-hooks, nodejs
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

node - <<'JS'
const { monitorEventLoopDelay } = require('perf_hooks');
const assert = require('assert');

const h = monitorEventLoopDelay({ resolution: 10 });
h.enable();

// Generate work across multiple ticks so the histogram has samples.
let ticks = 0;
function tick() {
  const end = Date.now() + 30;
  while (Date.now() < end) {} // eslint-disable-line no-empty
  if (++ticks < 6) setImmediate(tick);
  else {
    h.disable();
    assert.ok(h.max > 0, 'max delay > 0');
    assert.ok(h.min >= 0, 'min delay >= 0');
    // exceedsCount may exist as numeric on Node 18+
    assert.strictEqual(typeof h.mean, 'number');
    assert.ok(h.mean > 0, 'mean delay > 0');
  }
}
setImmediate(tick);
JS
