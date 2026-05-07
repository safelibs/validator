#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r13-bandjoin-three-uchar-bands
# @title: ruby-vips bandjoin of three single-band uchar images yields a 3-band image with stacked pixels
# @description: Builds three 3x3 single-band uchar images of constants 11, 22, 33, joins them with bandjoin, and verifies the resulting image has bands == 3 and getpoint(1, 1) returns [11.0, 22.0, 33.0], asserting libvips stacks the operands in band order.
# @timeout: 60
# @tags: usage, vips, ruby, bandjoin
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
a = (Vips::Image.black(3, 3) + 11).cast(:uchar)
b = (Vips::Image.black(3, 3) + 22).cast(:uchar)
c = (Vips::Image.black(3, 3) + 33).cast(:uchar)
joined = a.bandjoin([b, c])
raise "bandjoin bands=#{joined.bands}" unless joined.bands == 3
pt = joined.getpoint(1, 1)
raise "bandjoin pt=#{pt.inspect}" unless pt == [11.0, 22.0, 33.0]
puts "bandjoin pt=#{pt.inspect}"
RUBY
