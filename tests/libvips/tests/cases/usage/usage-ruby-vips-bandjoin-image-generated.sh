#!/usr/bin/env bash
# @testcase: usage-ruby-vips-bandjoin-image-generated
# @title: ruby-vips generated bandjoin image
# @description: Bandjoins two generated grayscale images with ruby-vips and verifies the resulting multiband channel payload.
# @timeout: 120
# @tags: usage
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-bandjoin-image-generated"
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

left = gray_image(2, 1, [10, 20])
right = gray_image(2, 1, [30, 40])
out = left.bandjoin(right)
first = out.extract_band(0).write_to_memory.bytes
second = out.extract_band(1).write_to_memory.bytes
raise 'bandjoin image mismatch' unless out.bands == 2 && first == [10, 20] && second == [30, 40]
puts out.bands
RUBY
