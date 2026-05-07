#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r14-rank-min-of-3x3-window
# @title: ruby-vips Image#rank with index 0 and 3x3 window picks the per-window minimum
# @description: Builds a 5x5 uniform-grey single-band uchar image with a single pepper pixel of value 5 in the centre, applies Vips::Image#rank(3, 3, 0) (rank-0 of a 3x3 window is the minimum), and verifies the centre pixel becomes 5 (the pepper) and an unaffected far-corner pixel remains the background grey value, asserting libvips' rank operator selects the windowed minimum exactly.
# @timeout: 60
# @tags: usage, vips, ruby, rank, min
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
grey = 200
pixels = Array.new(5 * 5, grey)
pixels[2 * 5 + 2] = 5  # pepper at centre
src = Vips::Image.new_from_memory(pixels.pack('C*'), 5, 5, 1, :uchar)

filtered = src.rank(3, 3, 0)
raise "filtered dims=#{filtered.width}x#{filtered.height}" unless filtered.width == 5 && filtered.height == 5
raise "filtered bands=#{filtered.bands}" unless filtered.bands == 1

# A 3x3 window centred on (2,2) sees the pepper, so its minimum is 5.
centre = filtered.getpoint(2, 2)
raise "centre=#{centre.inspect}" unless centre == [5.0]

# The far corners do not see the pepper through their 3x3 windows, so they
# remain at the background value (grey).
[[0, 0], [4, 4], [0, 4], [4, 0]].each do |x, y|
  v = filtered.getpoint(x, y)
  raise "edge (#{x},#{y})=#{v.inspect}" unless v == [grey.to_f]
end
puts "rank min ok"
RUBY
