#!/usr/bin/env bash
# @testcase: usage-ruby-vips-gravity-generated
# @title: ruby-vips generated gravity crop
# @description: Crops a generated grayscale image with ruby-vips gravity and verifies the centered pixel payload.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-gravity-generated"
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

image = gray_image(3, 3, [1, 2, 3, 4, 5, 6, 7, 8, 9])
out = image.gravity(:centre, 2, 2)
raise 'gravity mismatch' unless out.width == 2 && out.height == 2
raise 'gravity payload mismatch' unless out.write_to_memory.bytes == [1, 2, 4, 5]
puts "gravity #{out.width}x#{out.height}"
RUBY
