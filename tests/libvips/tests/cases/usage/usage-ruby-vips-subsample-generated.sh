#!/usr/bin/env bash
# @testcase: usage-ruby-vips-subsample-generated
# @title: ruby-vips generated subsample
# @description: Exercises ruby-vips generated subsample through a dependent-client usage scenario.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-subsample-generated"
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

image = gray_image(4, 4, Array.new(16, 90))
out = image.subsample(2, 2)
raise 'subsample mismatch' unless out.width == 2 && out.height == 2
puts "subsample #{out.width}x#{out.height}"
RUBY
