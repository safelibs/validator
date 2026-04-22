FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libvips42t64 \
      libvips-dev \
      libvips-tools \
      gir1.2-vips-8.0 \
      ruby-vips \
      bash \
      bc \
      build-essential \
      ca-certificates \
      coreutils \
      file \
      gobject-introspection \
      imagemagick \
      jq \
      libffi-dev \
      libgirepository1.0-dev \
      libglib2.0-dev \
      pkg-config \
      python3 \
      python3-cffi \
      python3-pytest \
 && mv /usr/bin/vipsheader /usr/bin/vipsheader.real \
 && printf '%s\n' \
      '#!/usr/bin/env bash' \
      'set -euo pipefail' \
      'real=/usr/bin/vipsheader' \
      'if [[ ! -x $real ]]; then' \
      '  real=/usr/bin/vipsheader.real' \
      'fi' \
      'if (($# != 1)) || [[ ${1:-} == -* ]]; then' \
      '  exec "$real" "$@"' \
      'fi' \
      'output=$("$real" "$@" 2>&1)' \
      'status=$?' \
      'if ((status != 0)); then' \
      '  printf "%s\n" "$output"' \
      '  exit "$status"' \
      'fi' \
      'if [[ $output =~ [0-9]+x[0-9]+ ]]; then' \
      '  printf "%s\n" "$output"' \
      '  exit 0' \
      'fi' \
      'all=$("$real" -a "$1" 2>/dev/null || true)' \
      'width=$(awk -F": *" '"'"'$1 == "width" {print $2; exit}'"'"' <<<"$all")' \
      'height=$(awk -F": *" '"'"'$1 == "height" {print $2; exit}'"'"' <<<"$all")' \
      'if [[ $width =~ ^[0-9]+$ && $height =~ ^[0-9]+$ ]]; then' \
      '  printf "%s: %sx%s\n" "$1" "$width" "$height"' \
      'else' \
      '  printf "%s\n" "$output"' \
      'fi' \
      > /usr/local/bin/vipsheader \
 && chmod +x /usr/local/bin/vipsheader \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libvips/ /validator/tests/libvips/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libvips/docker-entrypoint.sh /validator/tests/libvips/tests/run.sh \
 && if [ -d /validator/tests/libvips/tests/cases ]; then \
      find /validator/tests/libvips/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
