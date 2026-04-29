#!/usr/bin/env bash
# @testcase: usage-ruby-vips-memory-png-roundtrip-batch11
# @title: ruby-vips PNG memory roundtrip
# @description: Writes a PNG to memory and reloads it with ruby-vips.
# @timeout: 180
# @tags: usage, vips, ruby
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id="usage-ruby-vips-memory-png-roundtrip-batch11"
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

image = gray_image(2, 2, [1, 2, 3, 4])
data = image.write_to_buffer(".png")
reload = Vips::Image.new_from_buffer(data, "")
raise "png memory" unless bytes(reload) == [1, 2, 3, 4]
puts "png #{data.bytesize}"
RUBY
