#!/usr/bin/env bash
# @testcase: usage-ruby-vips-add-image-generated
# @title: ruby-vips generated add image
# @description: Adds two generated images with ruby-vips and verifies the resulting per-pixel summed payload.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-add-image-generated"
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

left = gray_image(2, 1, [5, 15])
right = gray_image(2, 1, [2, 3])
out = (left + right).cast(:uchar)
raise 'add image mismatch' unless out.write_to_memory.bytes == [7, 18]
puts out.write_to_memory.bytes.last
RUBY
