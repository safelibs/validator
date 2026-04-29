#!/usr/bin/env bash
# @testcase: usage-ruby-vips-copy-resolution-generated
# @title: ruby-vips generated copy resolution
# @description: Copies a generated image with ruby-vips while overriding its resolution metadata and verifies the new xres and yres values.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-copy-resolution-generated"
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

image = gray_image(2, 3, [1, 2, 3, 4, 5, 6])
out = image.copy(xres: 2.0, yres: 3.0)
raise 'copy resolution mismatch' unless (out.xres - 2.0).abs < 0.01 && (out.yres - 3.0).abs < 0.01
puts "#{out.xres}:#{out.yres}"
RUBY
