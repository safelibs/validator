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
      jq \
      libffi-dev \
      libgirepository1.0-dev \
      libglib2.0-dev \
      pkg-config \
      python3 \
      python3-cffi \
      python3-pytest \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libvips/ /validator/tests/libvips/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libvips/docker-entrypoint.sh /validator/tests/libvips/tests/run.sh \
 && if [ -d /validator/tests/libvips/tests/cases ]; then \
      find /validator/tests/libvips/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
