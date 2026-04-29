#!/usr/bin/env bash
# @testcase: usage-ruby-vips-resize-generated
# @title: ruby-vips resize generated image
# @description: Exercises ruby-vips resize generated image through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-resize-generated"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]

def gray_image(width, height, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, 1, :uchar)
end

def multiband_image(width, height, bands, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, bands, :uchar)
end

def gray_pixel(image, x, y)
  image.extract_area(x, y, 1, 1).write_to_memory.bytes[0]
end

image = gray_image(4, 4, Array.new(16, 40))
out = image.resize(0.5)
raise 'resize mismatch' unless out.width == 2 && out.height == 2
puts "resize #{out.width}x#{out.height}"
RUBY
