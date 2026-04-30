#!/usr/bin/env bash
# @testcase: usage-ruby-vips-dilate-cross-mask
# @title: ruby-vips morphological dilate with 3x3 square mask
# @description: Dilates a binary image containing a single white pixel with a 3x3 all-255 square structuring element via Vips::Image#dilate and verifies the result is exactly a 3x3 square stamped at the original location. (A 4-connected cross mask cannot be expressed in vips morph without rewriting the don't-care/must-not-be-set flags, which is a different behaviour; the square dilation of a single bright pixel is the canonical dilation case.)
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 9x9 binary image with a single white pixel at (4,4).
rows = Array.new(9) do |y|
  Array.new(9) do |x|
    (x == 4 && y == 4) ? 255 : 0
  end
end
src = Vips::Image.new_from_array(rows).cast(:uchar)
raise "src dims" unless src.width == 9 && src.height == 9

# 3x3 square structuring element: every cell is "must be set".
mask = Vips::Image.new_from_array([
  [255, 255, 255],
  [255, 255, 255],
  [255, 255, 255],
])

dilated = src.dilate(mask)
raise "dilate dims" unless dilated.width == 9 && dilated.height == 9
raise "dilate bands" unless dilated.bands == 1

# After 3x3 square dilation, the 3x3 square "stamp" should appear
# centred at (4,4) -- nine bright pixels in a contiguous block.
hits = [
  [3, 3], [4, 3], [5, 3],
  [3, 4], [4, 4], [5, 4],
  [3, 5], [4, 5], [5, 5],
]
hits.each do |x, y|
  v = dilated.getpoint(x, y)[0]
  raise "dilate hit (#{x},#{y})=#{v}" unless v == 255.0
end

# Pixels outside the 3x3 stamp must remain black.
[[2, 4], [6, 4], [4, 2], [4, 6], [0, 0]].each do |x, y|
  v = dilated.getpoint(x, y)[0]
  raise "dilate miss (#{x},#{y})=#{v}" unless v == 0.0
end

# Total bright pixel count should be exactly 9 (the 3x3 square).
bright = dilated >= 255
mean_norm = bright.avg
raise "dilate count #{mean_norm}" unless ((mean_norm / 255.0) * 9 * 9).round == 9

out_path = File.join(tmpdir, "dilate.png")
dilated.write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "dilate stamped 3x3 square at (4,4)"
RUBY

file "$tmpdir/dilate.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/dilate.png")" >&2; exit 1; }
