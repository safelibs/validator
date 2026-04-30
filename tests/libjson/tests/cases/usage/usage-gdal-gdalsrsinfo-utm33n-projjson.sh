#!/usr/bin/env bash
# @testcase: usage-gdal-gdalsrsinfo-utm33n-projjson
# @title: GDAL gdalsrsinfo UTM 33N PROJJSON
# @description: Resolves EPSG:32633 with gdalsrsinfo -o projjson and verifies the JSON document reports a ProjectedCRS whose name advertises the WGS 84 / UTM zone 33N projection.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-gdalsrsinfo-utm33n-projjson"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

gdalsrsinfo -o projjson EPSG:32633 >"$tmpdir/out.json"
jq -e '
  .type == "ProjectedCRS"
  and (.name | test("UTM zone 33N"))
  and .id.authority == "EPSG"
  and ((.id.code | tostring) == "32633")
' "$tmpdir/out.json"
