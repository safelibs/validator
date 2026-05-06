#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r11-scaleimage-normalizes-to-uchar
# @title: ruby-vips Image#scaleimage normalizes a 2x3 ramp to the full 0..255 uchar range
# @description: Builds a 2x3 integer ramp 10..60 via Image.new_from_array and verifies Image#scaleimage emits a uchar image whose extrema are exactly 0 and 255.
# @timeout: 60
# @tags: usage, vips, ruby, normalize
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = Vips::Image.new_from_array([[10, 20, 30], [40, 50, 60]])
si = img.scaleimage
raise "format #{si.format}" unless si.format == :uchar
raise "min #{si.min}" unless si.min == 0.0
raise "max #{si.max}" unless si.max == 255.0
puts "scaleimage normalised to 0..255 uchar"
RUBY
