#!/usr/bin/env bash
# @testcase: usage-ruby-vips-r19-ifthenelse-true-mask-selects-then
# @title: ruby-vips Image#ifthenelse with an all-true mask returns the then-branch verbatim
# @description: Builds a 4x4 uchar all-ones mask (value 1) and two distinct constant uchar images "thn" (value 90) and "els" (value 30), calls mask.ifthenelse(thn, els), and asserts the result has the same dimensions as the inputs and that every output pixel equals 90 (avg=min=max=90), confirming libvips' conditional selection routes every position into the then-branch when the predicate is non-zero everywhere.
# @timeout: 60
# @tags: usage, vips, ruby, ifthenelse, r19
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

ruby -rvips - <<'RUBY'
mask = (Vips::Image.black(4, 4) + 1).cast(:uchar)
thn  = (Vips::Image.black(4, 4) + 90).cast(:uchar)
els  = (Vips::Image.black(4, 4) + 30).cast(:uchar)
out = mask.ifthenelse(thn, els)
raise "dims" unless out.width == 4 && out.height == 4
raise "avg=#{out.avg}" unless out.avg == 90
raise "min=#{out.min}" unless out.min == 90
raise "max=#{out.max}" unless out.max == 90
puts "ifthenelse avg=#{out.avg}"
RUBY
