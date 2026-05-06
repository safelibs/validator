#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r9-extract-area
# @title: ruby-vips extract_area crops region
# @description: Extracts a 4x4 sub-region from a 16x16 image via extract_area and verifies the output dimensions and that pixels match the original at the offset.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - <<'RUBY'
src = Vips::Image.black(16, 16, bands: 1)
src = src + Vips::Image.xyz(16, 16).extract_band(0)
src = src.cast(:uchar)
crop = src.extract_area(4, 4, 4, 4)
raise "dim #{crop.width}x#{crop.height}" unless crop.width == 4 && crop.height == 4
raise "px #{crop.getpoint(0, 0)}" unless crop.getpoint(0, 0) == [4.0]
raise "px #{crop.getpoint(3, 0)}" unless crop.getpoint(3, 0) == [7.0]
RUBY
