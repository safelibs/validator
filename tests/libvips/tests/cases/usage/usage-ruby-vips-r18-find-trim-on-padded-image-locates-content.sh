#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r18-find-trim-on-padded-image-locates-content
# @title: ruby-vips Image#find_trim on a black-padded constant image returns the inner bounding box
# @description: Builds a 4x4 uchar constant image (value 200), embeds it at (3, 2) into a 10x8 canvas with extend :black, calls find_trim with background: [0] and threshold: 1 to locate non-background content, and asserts the returned [left, top, width, height] equals [3, 2, 4, 4], confirming libvips' find_trim bounding-box detection against a black background.
# @timeout: 60
# @tags: usage, vips, ruby, find_trim, r18
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
inner = (Vips::Image.black(4, 4) + 200).cast(:uchar)
canvas = inner.embed(3, 2, 10, 8, extend: :black)
left, top, w, h = canvas.find_trim(background: [0], threshold: 1)
raise "left=#{left}"   unless left == 3
raise "top=#{top}"     unless top == 2
raise "width=#{w}"     unless w == 4
raise "height=#{h}"    unless h == 4
puts "find_trim #{left},#{top} #{w}x#{h}"
RUBY
