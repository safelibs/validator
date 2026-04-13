FROM ubuntu:24.04

ARG VALIDATOR_TEST_MODE=original
ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      file \
      liblzma-dev \
      libxml2-dev \
      libxml2-utils \
      perl \
      pkg-config \
      python3 \
      python3-libxml2 \
      xsltproc \
      zlib1g-dev \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libxml/ /validator/tests/libxml/
COPY port/ /validator/port/

RUN if [ -x /validator/port/original/configure ]; then \
      triplet="$(gcc -print-multiarch)"; \
      cd /validator/port/original; \
      ./configure --prefix=/usr --libdir="/usr/lib/$triplet" --without-python; \
      make -j"$(nproc)"; \
      rm -rf /validator/tests/libxml/original-package-root; \
      make DESTDIR=/validator/tests/libxml/original-package-root install; \
      if [ "$VALIDATOR_TEST_MODE" = "original" ]; then \
        make install; \
        ldconfig; \
      fi; \
    fi

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/libxml/docker-entrypoint.sh \
    /validator/tests/libxml/tests/run.sh
