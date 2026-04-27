#!/usr/bin/env bash
set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

case_id=${1:?missing testcase id}
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

def gray_pixel(image, x, y)
  image.extract_area(x, y, 1, 1).cast(:uchar).write_to_memory.bytes[0]
end

case case_id
when "usage-ruby-vips-multiply-constant-tenth"
  image = gray_image(2, 1, [3, 5])
  out = (image * 4).cast(:uchar)
  raise "multiply mismatch" unless out.write_to_memory.bytes == [12, 20]
  puts "multiply #{out.write_to_memory.bytes.join(',')}"
when "usage-ruby-vips-add-constant-tenth"
  image = gray_image(2, 1, [10, 20])
  out = (image + 7).cast(:uchar)
  raise "add mismatch" unless out.write_to_memory.bytes == [17, 27]
  puts "add #{out.write_to_memory.bytes.join(',')}"
when "usage-ruby-vips-max-scalar-generated"
  image = gray_image(3, 1, [10, 200, 30])
  raise "max mismatch" unless image.max == 200.0
  puts "max #{image.max}"
when "usage-ruby-vips-min-scalar-generated"
  image = gray_image(3, 1, [50, 5, 200])
  raise "min mismatch" unless image.min == 5.0
  puts "min #{image.min}"
when "usage-ruby-vips-avg-scalar-generated"
  image = gray_image(2, 1, [40, 60])
  raise "avg mismatch" unless (image.avg - 50.0).abs < 0.01
  puts "avg #{image.avg}"
when "usage-ruby-vips-deviate-zero-generated"
  image = gray_image(3, 1, [25, 25, 25])
  raise "deviate mismatch" unless image.deviate < 0.01
  puts "deviate #{image.deviate}"
when "usage-ruby-vips-bandsplit-three-generated"
  image = multiband_image(1, 1, 3, [11, 22, 33])
  bands = image.bandsplit
  raise "split count mismatch" unless bands.length == 3
  raise "split values mismatch" unless bands.map { |b| b.write_to_memory.bytes[0] } == [11, 22, 33]
  puts "split #{bands.length}"
when "usage-ruby-vips-cast-int-generated"
  image = gray_image(2, 1, [40, 80])
  out = image.cast(:int)
  raise "cast format mismatch" unless out.format.to_s == "int"
  puts "cast #{out.format}"
when "usage-ruby-vips-bandbool-and-generated"
  a = gray_image(2, 1, [255, 240]).cast(:uchar)
  b = gray_image(2, 1, [128, 240]).cast(:uchar)
  out = (a & b).cast(:uchar)
  raise "and mismatch" unless out.write_to_memory.bytes == [128, 240]
  puts "and #{out.write_to_memory.bytes.join(',')}"
when "usage-ruby-vips-bandor-generated"
  a = gray_image(2, 1, [16, 1]).cast(:uchar)
  b = gray_image(2, 1, [1, 2]).cast(:uchar)
  out = (a | b).cast(:uchar)
  raise "or mismatch" unless out.write_to_memory.bytes == [17, 3]
  puts "or #{out.write_to_memory.bytes.join(',')}"
else
  raise "unknown libvips tenth-batch usage case: #{case_id}"
end
RUBY
