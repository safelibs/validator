#!/usr/bin/env bash
# @testcase: usage-gdal-gdalsrsinfo-wkt2-2019
# @title: GDAL gdalsrsinfo WKT2 2019
# @description: Runs gdalsrsinfo with the wkt2_2019 output format for EPSG:4326 and verifies the GEOGCRS root keyword is present.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalsrsinfo-wkt2-2019"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gdalsrsinfo -o wkt2_2019 EPSG:4326 >"$tmpdir/out.wkt"
validator_assert_contains "$tmpdir/out.wkt" 'GEOGCRS'
validator_assert_contains "$tmpdir/out.wkt" 'WGS 84'
