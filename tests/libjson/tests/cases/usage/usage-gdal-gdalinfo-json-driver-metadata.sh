#!/usr/bin/env bash
# @testcase: usage-gdal-gdalinfo-json-driver-metadata
# @title: GDAL gdalinfo --formats reports GeoJSON
# @description: Runs gdalinfo --formats and verifies the output enumerates the GeoJSON vector driver entry.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ogrinfo --formats >"$tmpdir/formats.txt"
validator_assert_contains "$tmpdir/formats.txt" 'GeoJSON'
