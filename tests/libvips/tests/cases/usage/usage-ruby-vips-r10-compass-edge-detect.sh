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

# Step edge: left half = 0, right half = 200 across an 8x5 image.
w, h = 8, 5
pixels = []
h.times do
  pixels.concat(Array.new(w / 2, 0) + Array.new(w / 2, 200))
end
img = Vips::Image.new_from_memory(pixels.pack('C*'), w, h, 1, :uchar)

# 3x3 horizontal Sobel-like derivative (odd, square) — required by compass.
mask = Vips::Image.new_from_array([[-1, 0, 1], [-2, 0, 2], [-1, 0, 1]], 1)
out = img.compass(mask, times: 4, angle: :d90, combine: :max, precision: :integer)
raise "dims" unless out.width == w && out.height == h
raise "bands" unless out.bands == 1

mid_y = 2
edge_response = out.getpoint(w / 2, mid_y)[0]
flat_left = out.getpoint(0, mid_y)[0]
flat_right = out.getpoint(w - 1, mid_y)[0]

raise "edge<=flat_left edge=#{edge_response} flat=#{flat_left}" unless edge_response > flat_left
raise "edge<=flat_right edge=#{edge_response} flat=#{flat_right}" unless edge_response > flat_right

puts "compass edge=#{edge_response} flat_left=#{flat_left} flat_right=#{flat_right}"
RUBY
