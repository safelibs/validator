#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r11-fwfft-invfft-roundtrip
# @title: ruby-vips fwfft followed by invfft preserves the input mean
# @description: Computes the forward FFT of a constant-100 8x8 double image then the inverse FFT and verifies the real component recovers the constant 100 within 1e-6.
# @timeout: 60
# @tags: usage, vips, ruby, fft
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(8, 8) + 100).cast(:double)
roundtrip = img.fwfft.invfft.real
diff = (roundtrip.avg - 100.0).abs
raise "fft roundtrip avg=#{roundtrip.avg}" unless diff < 1e-6
puts "fft roundtrip avg=#{roundtrip.avg}"
RUBY
