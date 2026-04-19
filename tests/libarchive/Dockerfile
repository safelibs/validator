FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libarchive13t64 \
      libarchive-dev \
      libarchive-tools \
      python3-libarchive-c \
      bash \
      build-essential \
      bzip2 \
      ca-certificates \
      coreutils \
      file \
      gzip \
      jq \
      libacl1-dev \
      lz4 \
      lzip \
      lzop \
      pkg-config \
      python3 \
      xz-utils \
      zstd \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libarchive/ /validator/tests/libarchive/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libarchive/docker-entrypoint.sh /validator/tests/libarchive/tests/run.sh \
 && if [ -d /validator/tests/libarchive/tests/cases ]; then \
      find /validator/tests/libarchive/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
