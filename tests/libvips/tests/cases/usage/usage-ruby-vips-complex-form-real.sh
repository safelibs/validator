#!/usr/bin/env bash
# @testcase: usage-ruby-vips-complex-form-real
# @title: ruby-vips complexform pairs bands and complexget extracts real
# @description: Builds a complex-valued image from two real-valued single-band images via Vips::Image#complexform (the libvips operation name is one word; complex_form is not a registered operation) and verifies that complexget(:real) recovers the original real channel pixel-for-pixel.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips - "$tmpdir" <<'RUBY'
tmpdir = ARGV[0]

# Two distinct single-band float images that will form the real and imaginary
# parts of a complex image. The real part has unique values per pixel so any
# round-trip mismatch is easy to spot.
real_pixels = [
  1.0, 2.0, 3.0, 4.0,
  5.0, 6.0, 7.0, 8.0,
  9.0, 10.0, 11.0, 12.0,
]
imag_pixels = [
  100.0, 110.0, 120.0, 130.0,
  140.0, 150.0, 160.0, 170.0,
  180.0, 190.0, 200.0, 210.0,
]

real_img = Vips::Image.new_from_memory(real_pixels.pack('d*'), 4, 3, 1, :double)
imag_img = Vips::Image.new_from_memory(imag_pixels.pack('d*'), 4, 3, 1, :double)
raise "real dims" unless real_img.width == 4 && real_img.height == 3 && real_img.bands == 1
raise "imag dims" unless imag_img.width == 4 && imag_img.height == 3 && imag_img.bands == 1

# complexform expects a 1-band "second" image and returns a 1-band complex image.
complex_img = real_img.complexform(imag_img)
raise "complex bands" unless complex_img.bands == 1
raise "complex dims" unless complex_img.width == 4 && complex_img.height == 3
raise "complex format" unless complex_img.format == :dpcomplex || complex_img.format == :complex

# complexget(:real) pulls back the real component as a regular real-valued image.
recovered = complex_img.complexget(:real)
raise "recovered bands" unless recovered.bands == 1
raise "recovered dims" unless recovered.width == 4 && recovered.height == 3

[[0, 0, 1.0], [3, 0, 4.0], [0, 2, 9.0], [3, 2, 12.0]].each do |x, y, expected|
  v = recovered.getpoint(x, y)[0]
  raise "real(#{x},#{y})=#{v} want #{expected}" unless (v - expected).abs < 1e-9
end

imag_back = complex_img.complexget(:imag)
raise "imag(2,1) #{imag_back.getpoint(2, 1)}" unless (imag_back.getpoint(2, 1)[0] - 160.0).abs < 1e-9

puts "complexform/get real(0,0)=#{recovered.getpoint(0, 0)[0]} imag(2,1)=#{imag_back.getpoint(2, 1)[0]}"
RUBY
