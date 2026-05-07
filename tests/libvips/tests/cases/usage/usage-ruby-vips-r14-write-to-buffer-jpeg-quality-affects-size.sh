#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r14-write-to-buffer-jpeg-quality-affects-size
# @title: ruby-vips write_to_buffer('.jpg') with low Q is smaller than with high Q for noisy input
# @description: Generates a 64x64 Gaussian noise image (which is incompressible enough that JPEG quality clearly impacts size), writes it to a JPEG buffer with Q=10 and Q=95 via write_to_buffer('.jpg', Q: ...), and verifies both buffers are non-empty and the Q=10 buffer is strictly smaller than the Q=95 buffer, asserting libvips honours the Q quality parameter on the JPEG encoder.
# @timeout: 60
# @tags: usage, vips, ruby, jpeg, buffer, quality
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = Vips::Image.gaussnoise(64, 64, mean: 128, sigma: 40).cast(:uchar)
lo = img.write_to_buffer('.jpg', Q: 10)
hi = img.write_to_buffer('.jpg', Q: 95)
raise "lo empty" unless lo.bytesize > 0
raise "hi empty" unless hi.bytesize > 0
raise "Q=10 (#{lo.bytesize}) not < Q=95 (#{hi.bytesize})" unless lo.bytesize < hi.bytesize
puts "jpeg quality lo=#{lo.bytesize} hi=#{hi.bytesize}"
RUBY
