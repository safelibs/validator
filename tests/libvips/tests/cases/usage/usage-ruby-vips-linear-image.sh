#!/usr/bin/env bash
# @testcase: usage-ruby-vips-linear-image
# @title: ruby-vips linear image
# @description: Uses ruby-vips to run libvips linear image behavior.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips -e "image=Vips::Image.black(4,4)+10; out=image.linear(2,1); puts \"avg=#{out.avg}\"" "$tmpdir/out.png"
