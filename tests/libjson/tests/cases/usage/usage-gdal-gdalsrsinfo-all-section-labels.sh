#!/usr/bin/env bash
# @testcase: usage-gdal-gdalsrsinfo-all-section-labels
# @title: GDAL gdalsrsinfo -o all section labels
# @description: Runs gdalsrsinfo -o all on EPSG:3857 and verifies that the multi-format dump exposes the PROJ.4, OGC WKT1, OGC WKT2:2019, and PROJJSON section headers Ubuntu 24.04's gdalsrsinfo emits, with PROJJSON parseable as valid JSON.
# @timeout: 120
# @tags: usage, gdal, srs, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalsrsinfo-all-section-labels"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gdalsrsinfo -o all EPSG:3857 >"$tmpdir/all.txt"
validator_require_file "$tmpdir/all.txt"

validator_assert_contains "$tmpdir/all.txt" 'PROJ.4 :'
validator_assert_contains "$tmpdir/all.txt" 'OGC WKT1 :'
validator_assert_contains "$tmpdir/all.txt" 'OGC WKT2:2019 :'
validator_assert_contains "$tmpdir/all.txt" 'PROJJSON :'

# Sanity check the embedded PROJJSON block is recognizable JSON parseable
# through json-c by re-fetching it directly and validating its structure.
gdalsrsinfo -o projjson EPSG:3857 >"$tmpdir/projjson.json"
jq -e '.type == "ProjectedCRS" and (.id.code == 3857)' "$tmpdir/projjson.json"
