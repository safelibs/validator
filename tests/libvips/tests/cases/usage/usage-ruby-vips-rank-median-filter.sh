#!/usr/bin/env bash
# @testcase: usage-ruby-vips-rank-median-filter
# @title: ruby-vips rank median filter removes salt noise
# @description: Builds a uniform-grey image with a single bright salt pixel and verifies that Vips::Image#rank with a 3x3 window and median index restores the salt pixel to the surrounding grey value while leaving the background untouched.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 5x5 uniform grey image with one outlier in the middle.
grey = 50
pixels = Array.new(5 * 5, grey)
pixels[2 * 5 + 2] = 250  # salt in the centre
src = Vips::Image.new_from_memory(pixels.pack('C*'), 5, 5, 1, :uchar)
raise "src bands" unless src.bands == 1
raise "centre is salt" unless src.getpoint(2, 2) == [250.0]

# 3x3 window has 9 elements; index 4 is the median.
filtered = src.rank(3, 3, 4)
raise "filtered dims" unless filtered.width == 5 && filtered.height == 5
raise "filtered bands" unless filtered.bands == 1

centre = filtered.getpoint(2, 2)
raise "centre after median #{centre.inspect}" unless centre == [grey.to_f]

# Edge pixels far from the salt remain at the background.
[[0, 0], [4, 4], [0, 4], [4, 0]].each do |x, y|
  v = filtered.getpoint(x, y)
  raise "edge (#{x},#{y})=#{v.inspect}" unless v == [grey.to_f]
end

puts "rank median ok centre=#{centre}"
RUBY
