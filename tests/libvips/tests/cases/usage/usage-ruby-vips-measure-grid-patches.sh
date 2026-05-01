#!/usr/bin/env bash
# @testcase: usage-ruby-vips-measure-grid-patches
# @title: ruby-vips measure colour chart patches
# @description: Builds a synthetic four-patch grayscale chart, measures it with Vips::Image#measure(4, 1), and verifies that the returned matrix carries one row per patch with the expected mean intensities.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Four uniform horizontal patches, 16 wide each, 16 tall, single band.
patch_w = 16
patch_h = 16
patches = [40, 90, 150, 210]
tiles = patches.map do |v|
  (Vips::Image.black(patch_w, patch_h) + v).cast(:uchar)
end
chart = Vips::Image.arrayjoin(tiles, across: 4)
raise "chart dims #{chart.width}x#{chart.height}" unless chart.width == patch_w * 4 && chart.height == patch_h

mat = chart.measure(4, 1)
# measure() returns a matrix with one column per band (1 here) and one row
# per patch. With a single-band input we expect a 1xN matrix.
raise "measure dims #{mat.width}x#{mat.height}" unless mat.width >= 1 && mat.height == 4

patches.each_with_index do |want, idx|
  got = mat.getpoint(0, idx).first
  raise "patch #{idx} mean #{got} (want #{want})" unless (got - want).abs < 0.5
end

puts "measure patches=#{patches.inspect}"
RUBY
