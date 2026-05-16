#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r21-find-trim-on-flat-image-returns-zero-area
# @title: ruby-vips Image#find_trim on a flat-background image reports no content area
# @description: Builds a 10x10 uchar image filled with constant 255 (interpreted as background), calls find_trim with the default background, and asserts the returned [left, top, width, height] yields a width or height of 0 (no content), exercising libvips' background trim detection on a fully-background image.
# @timeout: 60
# @tags: usage, vips, ruby, find-trim, r21
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
src = (Vips::Image.black(10, 10) + 255).cast(:uchar)
left, top, width, height = src.find_trim
# Flat image == all background: vips reports zero-area content rect.
raise "width=#{width} height=#{height}" unless width == 0 || height == 0
puts "find_trim flat l=#{left} t=#{top} w=#{width} h=#{height}"
RUBY
