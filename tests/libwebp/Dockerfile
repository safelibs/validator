FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      cmake \
      libgif-dev \
      libjpeg-dev \
      libpng-dev \
      libtiff-dev \
      libwebp-dev \
      pkg-config \
      webp \
 && rm -rf /var/lib/apt/lists/*

RUN triplet="$(gcc -print-multiarch)" \
 && mkdir -p "/validator/tests/libwebp/original-package-root/usr/lib/$triplet" \
 && cp -a /usr/lib/"$triplet"/libwebp*.so* /validator/tests/libwebp/original-package-root/usr/lib/"$triplet"/

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libwebp/ /validator/tests/libwebp/

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/libwebp/docker-entrypoint.sh \
    /validator/tests/libwebp/tests/run.sh
