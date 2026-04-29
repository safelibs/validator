#!/usr/bin/env bash
# @testcase: usage-ruby-vips-average-image
# @title: ruby-vips average image
# @description: Uses ruby-vips to run libvips average image behavior.
# @timeout: 180
# @tags: usage, ruby, image
# @client: ruby-vips

set -euo pipefail
source /validator/tests/_shared/runtime_helpers.sh

tmpdir=$(mktemp -d)
trap 'rm -rf "$tmpdir"' EXIT

ruby -rvips -e "image=Vips::Image.black(8,8,bands:1)+7; puts \"avg=#{image.avg}\"" "$tmpdir/out.png"
