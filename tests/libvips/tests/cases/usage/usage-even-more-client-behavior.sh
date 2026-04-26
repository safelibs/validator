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
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, 1, :uchar)
end

def multiband_image(width, height, bands, pixels)
  Vips::Image.new_from_memory(pixels.pack('C*'), width, height, bands, :uchar)
end

def gray_pixel(image, x, y)
  image.extract_area(x, y, 1, 1).write_to_memory.bytes[0]
end

case case_id
when 'usage-ruby-vips-rot270-generated'
  image = gray_image(2, 3, [1, 2, 3, 4, 5, 6])
  out = image.rot270
  raise 'bad size' unless out.width == 3 && out.height == 2
  puts "rot270 #{out.width}x#{out.height}"
when 'usage-ruby-vips-crop-generated'
  image = gray_image(4, 3, [1, 2, 3, 4, 5, 6, 7, 8, 9, 10, 11, 12])
  out = image.crop(1, 1, 2, 2)
  raise 'crop mismatch' unless gray_pixel(out, 0, 0) == 6 && gray_pixel(out, 1, 1) == 11
  puts "crop #{gray_pixel(out, 0, 0)} #{gray_pixel(out, 1, 1)}"
when 'usage-ruby-vips-resize-generated'
  image = gray_image(4, 4, Array.new(16, 40))
  out = image.resize(0.5)
  raise 'resize mismatch' unless out.width == 2 && out.height == 2
  puts "resize #{out.width}x#{out.height}"
when 'usage-ruby-vips-avg-generated'
  image = gray_image(2, 2, [10, 20, 30, 40])
  raise 'avg mismatch' unless (image.avg - 25.0).abs < 0.01
  puts "avg #{image.avg}"
when 'usage-ruby-vips-read-buffer-jpeg'
  image = multiband_image(2, 2, 3, [255, 0, 0, 0, 255, 0, 0, 0, 255, 255, 255, 0])
  buffer = image.write_to_buffer('.jpg')
  reload = Vips::Image.new_from_buffer(buffer, '')
  raise 'jpeg buffer mismatch' unless reload.width == 2 && reload.height == 2
  puts "jpeg-buffer #{reload.width}x#{reload.height}"
when 'usage-ruby-vips-png-buffer-roundtrip'
  image = gray_image(2, 2, [5, 15, 25, 35])
  buffer = image.write_to_buffer('.png')
  reload = Vips::Image.new_from_buffer(buffer, '')
  raise 'png roundtrip mismatch' unless gray_pixel(reload, 1, 1) == 35
  puts "png-buffer #{gray_pixel(reload, 1, 1)}"
when 'usage-ruby-vips-jpeg-buffer-roundtrip'
  image = multiband_image(2, 2, 3, [20, 30, 40, 50, 60, 70, 80, 90, 100, 110, 120, 130])
  buffer = image.write_to_buffer('.jpg')
  reload = Vips::Image.new_from_buffer(buffer, '')
  raise 'jpeg reload mismatch' unless reload.width == 2 && reload.height == 2
  puts "jpeg-roundtrip #{reload.width}x#{reload.height}"
when 'usage-ruby-vips-join-horizontal'
  left = gray_image(2, 1, [10, 20])
  right = gray_image(2, 1, [30, 40])
  out = left.join(right, :horizontal)
  raise 'join mismatch' unless out.width == 4 && gray_pixel(out, 3, 0) == 40
  puts "join #{out.width}"
when 'usage-ruby-vips-bandjoin-constant'
  image = gray_image(1, 1, [12])
  out = image.bandjoin(200)
  raise 'bandjoin mismatch' unless out.bands == 2
  puts "bands #{out.bands}"
when 'usage-ruby-vips-insert-generated-overlay'
  base = gray_image(4, 4, Array.new(16, 10))
  patch = gray_image(2, 2, Array.new(4, 200))
  out = base.insert(patch, 1, 1)
  raise 'insert mismatch' unless gray_pixel(out, 1, 1) == 200 && gray_pixel(out, 0, 0) == 10
  puts "insert #{gray_pixel(out, 1, 1)}"
else
  raise "unknown libvips even-more usage case: #{case_id}"
end
RUBY
