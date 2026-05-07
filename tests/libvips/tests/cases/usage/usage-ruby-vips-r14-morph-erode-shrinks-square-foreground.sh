#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r14-morph-erode-shrinks-square-foreground
# @title: ruby-vips Image#morph erode shrinks a 3x3 foreground square to its centre pixel
# @description: Constructs a 9x9 binary single-band uchar image with a 3x3 foreground square (255) centred at (4,4) on a 0 background, applies Vips::Image#morph(cross, :erode) with a 3x3 cross-shaped structuring element, and verifies the centre pixel stays 255 while each of the four arm pixels of the original block fall to 0, asserting libvips' morph erode collapses the foreground exactly along the structuring element.
# @timeout: 60
# @tags: usage, vips, ruby, morph, erode
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
w, h = 9, 9
pixels = Array.new(w * h, 0)
[3, 4, 5].each do |yy|
  [3, 4, 5].each do |xx|
    pixels[yy * w + xx] = 255
  end
end
img = Vips::Image.new_from_memory(pixels.pack('C*'), w, h, 1, :uchar)

cross = Vips::Image.new_from_array(
  [
    [128, 255, 128],
    [255, 255, 255],
    [128, 255, 128],
  ],
  1,
)

eroded = img.morph(cross, :erode)
raise "dims=#{eroded.width}x#{eroded.height}" unless eroded.width == w && eroded.height == h
raise "centre=#{eroded.getpoint(4, 4)[0]}" unless eroded.getpoint(4, 4)[0] == 255
[[4, 3], [4, 5], [3, 4], [5, 4]].each do |x, y|
  v = eroded.getpoint(x, y)[0]
  raise "arm (#{x},#{y})=#{v}" unless v == 0
end
puts "morph erode collapses 3x3 to centre"
RUBY
