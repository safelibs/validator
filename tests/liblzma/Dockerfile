FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      liblzma5 \
      liblzma-dev \
      xz-utils \
      apt-utils \
      bash \
      build-essential \
      ca-certificates \
      coreutils \
      dpkg-dev \
      file \
      gdb \
      jq \
      libarchive-dev \
      libarchive-tools \
      libboost-iostreams-dev \
      libtiff-dev \
      libxml2-utils \
      pkg-config \
      python3 \
      squashfs-tools \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY liblzma/ /validator/tests/liblzma/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/liblzma/docker-entrypoint.sh /validator/tests/liblzma/tests/run.sh \
 && if [ -d /validator/tests/liblzma/tests/cases ]; then \
      find /validator/tests/liblzma/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
