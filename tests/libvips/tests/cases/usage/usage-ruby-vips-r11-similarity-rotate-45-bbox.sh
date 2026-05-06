#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r11-similarity-rotate-45-bbox
# @title: ruby-vips Image#similarity at 45 degrees grows the bounding box from 8x8 to 11x11
# @description: Rotates an 8x8 constant image via Image#similarity(angle: 45) and verifies the output bounding box is 11x11 (ceil(8*sqrt(2)) = 12 minus the 1-pixel inner overlap that vips emits).
# @timeout: 60
# @tags: usage, vips, ruby, similarity, rotate
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = (Vips::Image.black(8, 8) + 1).cast(:uchar)
out = img.similarity(angle: 45)
raise "dims #{out.width}x#{out.height}" unless out.width == 11 && out.height == 11
puts "similarity 45 dims #{out.width}x#{out.height}"
RUBY
