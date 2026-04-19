#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
    trap 'rm -rf "$tmpdir"' EXIT

    cat >"$tmpdir/points.geojson" <<'JSON'
{"type":"FeatureCollection","features":[{"type":"Feature","properties":{"name":"alpha"},"geometry":{"type":"Point","coordinates":[1,2]}}]}
JSON
ogrinfo "$tmpdir/points.geojson" -al -so | tee "$tmpdir/out"
validator_assert_contains "$tmpdir/out" 'Feature Count: 1'