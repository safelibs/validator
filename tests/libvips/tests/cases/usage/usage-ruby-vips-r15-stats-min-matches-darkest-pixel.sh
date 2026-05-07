#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r15-stats-min-matches-darkest-pixel
# @title: ruby-vips Image#min returns exactly the darkest pixel value of a deterministic image
# @description: Constructs a 5x5 single-band uchar image whose 25 pixel values are a deterministic permutation in [0, 200), verifies Vips::Image#min equals the analytic minimum computed in pure Ruby over the same pixel array (5.0 for ((i*11)+7) % 200 over i in 0..24), asserting libvips' min reducer agrees with the input pixel data.
# @timeout: 60
# @tags: usage, vips, ruby, min
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
pixels = (0...25).map { |i| ((i * 11) + 7) % 200 }
src = Vips::Image.new_from_memory(pixels.pack('C*'), 5, 5, 1, :uchar)

expected = pixels.min.to_f
raise "src min=#{src.min} expected=#{expected}" unless src.min == expected
puts "min ok src=#{src.min} expected=#{expected}"
RUBY
