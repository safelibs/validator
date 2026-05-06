#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r11-maxpos-locates-bright-pixel
# @title: ruby-vips Image#maxpos returns value and (x,y) of brightest pixel
# @description: Draws a single 255 pixel at column 7 row 2 on a black 10x10 canvas and verifies Image#maxpos returns the triple [255, 7, 2].
# @timeout: 60
# @tags: usage, vips, ruby, statistics
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
img = Vips::Image.black(10, 10).draw_rect(255, 7, 2, 1, 1)
v, x, y = img.maxpos
raise "maxpos #{[v,x,y].inspect}" unless v == 255.0 && x == 7 && y == 2
puts "maxpos ok #{[v,x,y].inspect}"
RUBY
