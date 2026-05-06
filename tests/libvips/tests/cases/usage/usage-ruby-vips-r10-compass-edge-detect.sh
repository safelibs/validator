#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r10-compass-edge-detect
# @title: ruby-vips compass directional edge response
# @description: Convolves a step-edge image with a horizontal-derivative mask via Vips::Image#compass and verifies the maximum response sits on the edge column rather than in the flat regions.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Step edge: left half = 0, right half = 200 across a 6x3 image.
pixels = []
3.times do
  pixels.concat([0, 0, 0, 200, 200, 200])
end
img = Vips::Image.new_from_memory(pixels.pack('C*'), 6, 3, 1, :uchar)

mask = Vips::Image.new_from_array([[-1, 0, 1]], 1)
out = img.compass(mask, times: 4, angle: :d90, combine: :max, precision: :integer)
raise "dims" unless out.width == 6 && out.height == 3
raise "bands" unless out.bands == 1

mid_y = 1
edge_response = out.getpoint(3, mid_y)[0]
flat_left = out.getpoint(0, mid_y)[0]
flat_right = out.getpoint(5, mid_y)[0]

raise "edge<=flat_left edge=#{edge_response} flat=#{flat_left}" unless edge_response > flat_left
raise "edge<=flat_right edge=#{edge_response} flat=#{flat_right}" unless edge_response > flat_right

puts "compass edge=#{edge_response} flat_left=#{flat_left} flat_right=#{flat_right}"
RUBY
