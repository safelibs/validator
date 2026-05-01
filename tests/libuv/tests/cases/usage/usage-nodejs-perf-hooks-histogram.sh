#!/usr/bin/env bash
# @testcase: usage-nodejs-perf-hooks-histogram
# @title: Node.js perf_hooks createHistogram record
# @description: Creates a perf_hooks histogram, records several integer samples and verifies min, max and count reflect the recorded values.
# @timeout: 120
# @tags: usage, perf-hooks
# @client: nodejs

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

node >"$tmpdir/out" <<'JS'
const { createHistogram } = require('perf_hooks');
const h = createHistogram();
for (const v of [1, 5, 10, 25, 50]) h.record(v);
if (h.min !== 1) { console.error('min', h.min); process.exit(1); }
if (h.max < 50 || h.max > 51) { console.error('max', h.max); process.exit(1); }
const count = Number(h.count);
if (count !== 5) { console.error('count', count); process.exit(1); }
console.log('OK histogram', count, h.min);
JS

validator_assert_contains "$tmpdir/out" 'OK histogram 5 1'
