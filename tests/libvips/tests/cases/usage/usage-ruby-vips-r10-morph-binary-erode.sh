#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r10-morph-binary-erode
# @title: ruby-vips morph binary erode shrinks foreground square
# @description: Constructs a 5x5 binary image with a 3x3 foreground square and applies Vips::Image#morph with an erode 3x3 cross mask, verifying the foreground collapses to the centre pixel only.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

w, h = 9, 9
# 9x9 background of zeros with a 3x3 foreground square centred at (4,4).
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
raise "dims" unless eroded.width == w && eroded.height == h

# Erode with a 5-pixel cross-shaped structuring element collapses the 3x3 block
# down to the single centre pixel; the four arm positions of the original block
# fall to 0 because each one has at least one neighbour outside the foreground.
centre = eroded.getpoint(4, 4)[0]
above  = eroded.getpoint(4, 3)[0]
below  = eroded.getpoint(4, 5)[0]
left   = eroded.getpoint(3, 4)[0]
right  = eroded.getpoint(5, 4)[0]

raise "centre got=#{centre} want=255" unless centre == 255
raise "above  got=#{above}  want=0"   unless above  == 0
raise "below  got=#{below}  want=0"   unless below  == 0
raise "left   got=#{left}   want=0"   unless left   == 0
raise "right  got=#{right}  want=0"   unless right  == 0

puts "morph erode keeps centre, clears cross arms"
RUBY
