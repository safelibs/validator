#!/usr/bin/env bash
# @testcase: usage-gdal-ogr2ogr-write-bbox-geojson
# @title: GDAL ogr2ogr WRITE_BBOX GeoJSON
# @description: Converts a CSV point dataset to GeoJSON with ogr2ogr -lco WRITE_BBOX=YES and verifies that the rendered FeatureCollection bbox spans the input coordinate range.
# @timeout: 180
# @tags: usage, gdal, json
# @client: gdal

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-gdal-ogr2ogr-write-bbox-geojson"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

csv="$tmpdir/points.csv"
cat >"$csv" <<'CSV'
name,lon,lat
alpha,1,2
beta,5,6
gamma,3,4
CSV

vrt="$tmpdir/points.vrt"
cat >"$vrt" <<'XML'
<OGRVRTDataSource>
  <OGRVRTLayer name="points">
    <SrcDataSource>points.csv</SrcDataSource>
    <GeometryType>wkbPoint</GeometryType>
    <LayerSRS>EPSG:4326</LayerSRS>
    <GeometryField encoding="PointFromColumns" x="lon" y="lat"/>
  </OGRVRTLayer>
</OGRVRTDataSource>
XML

# OGR VRT resolves <SrcDataSource> paths relative to the current working
# directory, not the VRT file. Run ogr2ogr from $tmpdir so it can find
# points.csv next to points.vrt.
( cd "$tmpdir" && ogr2ogr -f GeoJSON "$tmpdir/out.geojson" "$vrt" -lco WRITE_BBOX=YES )
jq -e '
  (.bbox | length == 4)
  and (.bbox[0] == 1) and (.bbox[1] == 2)
  and (.bbox[2] == 5) and (.bbox[3] == 6)
' "$tmpdir/out.geojson"
