#!/usr/bin/env bash
# @testcase: usage-gdal-r16-ogr2ogr-formats-lists-geojson
# @title: GDAL ogr2ogr --formats output includes the GeoJSON driver
# @description: Runs ogr2ogr --formats and asserts the printed driver listing names "GeoJSON" — the vector driver backed by json-c that this library exists to support.
# @timeout: 60
# @tags: usage, gdal, json, drivers
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ogr2ogr --formats >"$tmpdir/formats.txt"
validator_assert_contains "$tmpdir/formats.txt" 'GeoJSON'
