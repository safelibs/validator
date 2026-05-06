#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r9-rot-90-shape
# @title: ruby-vips rot 90 swaps dimensions
# @description: Rotates a 32x16 image by 90 degrees and asserts the result is 16x32 with band count preserved.
# @timeout: 120
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - <<'RUBY'
img = Vips::Image.black(32, 16, bands: 3) + [40, 80, 120]
img = img.cast(:uchar)
rot = img.rot(:d90)
raise "dim #{rot.width}x#{rot.height}" unless rot.width == 16 && rot.height == 32
raise "bands #{rot.bands}" unless rot.bands == 3
rot2 = img.rot(:d180)
raise "dim2 #{rot2.width}x#{rot2.height}" unless rot2.width == 32 && rot2.height == 16
RUBY
