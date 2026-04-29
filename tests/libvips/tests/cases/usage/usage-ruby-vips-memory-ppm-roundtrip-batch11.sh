#!/usr/bin/env bash
# @testcase: usage-ruby-vips-memory-ppm-roundtrip-batch11
# @title: ruby-vips PPM memory roundtrip
# @description: Writes a PPM image to memory and reloads it with ruby-vips.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-memory-ppm-roundtrip-batch11"
tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$case_id" "$tmpdir" <<'RUBY'
case_id = ARGV[0]
tmpdir = ARGV[1]

def gray_image(width, height, pixels)
  Vips::Image.new_from_memory(pixels.pack("C*"), width, height, 1, :uchar)
end

def multiband_image(width, height, bands, pixels)
  Vips::Image.new_from_memory(pixels.pack("C*"), width, height, bands, :uchar)
end

def bytes(image)
  image.cast(:uchar).write_to_memory.bytes
end

image = multiband_image(1, 2, 3, [10, 20, 30, 40, 50, 60])
data = image.write_to_buffer(".ppm")
reload = Vips::Image.new_from_buffer(data, "")
raise "ppm memory" unless bytes(reload) == [10, 20, 30, 40, 50, 60]
puts "ppm #{data.bytesize}"
RUBY
