FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libwebp7 \
      libwebpdemux2 \
      libwebpmux3 \
      libwebpdecoder3 \
      libsharpyuv0 \
      libwebp-dev \
      libsharpyuv-dev \
      webp \
      bash \
      build-essential \
      ca-certificates \
      cmake \
      coreutils \
      file \
      jq \
      libgif-dev \
      libjpeg-dev \
      libpng-dev \
      libtiff-dev \
      pkg-config \
      python3 \
 && rm -rf /var/lib/apt/lists/*

RUN triplet="$(gcc -print-multiarch)" \
 && mkdir -p "/validator/tests/libwebp/original-package-root/usr/lib/$triplet" \
 && cp -a /usr/lib/"$triplet"/libwebp*.so* /validator/tests/libwebp/original-package-root/usr/lib/"$triplet"/

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libwebp/ /validator/tests/libwebp/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libwebp/docker-entrypoint.sh /validator/tests/libwebp/tests/run.sh \
 && if [ -d /validator/tests/libwebp/tests/cases ]; then \
      find /validator/tests/libwebp/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
