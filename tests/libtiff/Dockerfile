FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libtiff6 \
      libtiffxx6 \
      libtiff-dev \
      libtiff-tools \
      bash \
      build-essential \
      ca-certificates \
      coreutils \
      file \
      ghostscript \
      jq \
      libjbig-dev \
      libjpeg-dev \
      liblzma-dev \
      libwebp-dev \
      netpbm \
      pkg-config \
      poppler-utils \
      python3 \
      zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libtiff/ /validator/tests/libtiff/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libtiff/docker-entrypoint.sh /validator/tests/libtiff/tests/run.sh \
 && if [ -d /validator/tests/libtiff/tests/cases ]; then \
      find /validator/tests/libtiff/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
