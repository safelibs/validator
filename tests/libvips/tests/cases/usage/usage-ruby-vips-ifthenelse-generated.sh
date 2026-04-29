#!/usr/bin/env bash
# @testcase: usage-ruby-vips-ifthenelse-generated
# @title: ruby-vips generated ifthenelse
# @description: Applies ruby-vips ifthenelse to generated mask and image inputs and verifies the selected pixel payload.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-ifthenelse-generated"
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

mask = gray_image(2, 1, [0, 255])
then_image = gray_image(2, 1, [10, 20])
else_image = gray_image(2, 1, [30, 40])
out = mask.ifthenelse(then_image, else_image)
raise 'ifthenelse mismatch' unless out.write_to_memory.bytes == [30, 20]
puts "ifthenelse #{out.write_to_memory.bytes.join(',')}"
RUBY
