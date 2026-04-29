#!/usr/bin/env bash
# @testcase: usage-ruby-vips-rot90-generated
# @title: ruby-vips generated rot90
# @description: Rotates a generated image 90 degrees with ruby-vips and verifies the rotated dimensions.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-rot90-generated"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" <<'RUBY'
case_id = ARGV[0]

def gray_image(width, height, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, 1, :uchar)
end

def multiband_image(width, height, bands, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, bands, :uchar)
end

def gray_pixel(image, x, y)
  image.extract_area(x, y, 1, 1).cast(:uchar).write_to_memory.bytes[0]
end

image = gray_image(2, 1, [10, 20])
out = image.rot90
raise 'rot90 mismatch' unless out.width == 1 && out.height == 2
puts "#{out.width}x#{out.height}"
RUBY
