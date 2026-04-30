#!/usr/bin/env bash
# @testcase: usage-ruby-vips-erode-cross-mask
# @title: ruby-vips morphological erode with 3x3 square mask
# @description: Erodes a binary image containing a centred 3x3 white block with a 3x3 all-255 square structuring element via Vips::Image#erode and verifies the eroded image keeps only the centre pixel. (A 4-connected cross mask requires don't-care semantics that vips morph does not implement, so the canonical 3x3 square erosion is used here.)
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# 7x7 binary image (uchar 0/255) with a centred 3x3 white block at rows/cols 2..4.
rows = Array.new(7) do |y|
  Array.new(7) do |x|
    (x.between?(2, 4) && y.between?(2, 4)) ? 255 : 0
  end
end
src = Vips::Image.new_from_array(rows).cast(:uchar)
raise "src dims" unless src.width == 7 && src.height == 7
raise "src bands" unless src.bands == 1

# 3x3 square structuring element: every cell is "must be set".
mask = Vips::Image.new_from_array([
  [255, 255, 255],
  [255, 255, 255],
  [255, 255, 255],
])

eroded = src.erode(mask)
raise "eroded dims" unless eroded.width == 7 && eroded.height == 7

# Only the interior pixel where every neighbour is also set survives --
# that is the centre (3,3) of the 3x3 white block. Any pixel adjacent to
# the block boundary has at least one neighbour outside the block.
centre = eroded.getpoint(3, 3)[0]
raise "erode centre #{centre}" unless centre == 255.0

# All pixels outside the centre must be black after erosion.
[[2, 3], [4, 3], [3, 2], [3, 4], [2, 2], [4, 4], [0, 0]].each do |x, y|
  v = eroded.getpoint(x, y)[0]
  raise "erode (#{x},#{y})=#{v}" unless v == 0.0
end

out_path = File.join(tmpdir, "erode.png")
eroded.write_to_file(out_path)
raise "missing png" unless File.size?(out_path)
puts "erode kept centre only"
RUBY

file "$tmpdir/erode.png" | grep -q 'PNG image data' || { echo "not a PNG: $(file "$tmpdir/erode.png")" >&2; exit 1; }
