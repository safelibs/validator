#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r13-extract-band-index-one-of-three
# @title: ruby-vips extract_band(1) on a 3-band image returns the middle band as a 1-band image
# @description: Builds a 3-band image by bandjoining constants 10, 20, 30, calls extract_band(1), and verifies the result has bands == 1 and getpoint(0, 0) == [20.0], asserting libvips' band slicing returns the requested zero-indexed channel.
# @timeout: 60
# @tags: usage, vips, ruby, extract-band
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
a = (Vips::Image.black(2, 2) + 10).cast(:uchar)
b = (Vips::Image.black(2, 2) + 20).cast(:uchar)
c = (Vips::Image.black(2, 2) + 30).cast(:uchar)
joined = a.bandjoin([b, c])
band1 = joined.extract_band(1)
raise "extract bands=#{band1.bands}" unless band1.bands == 1
pt = band1.getpoint(0, 0)
raise "extract pt=#{pt.inspect}" unless pt == [20.0]
puts "extract_band(1) pt=#{pt.inspect}"
RUBY
