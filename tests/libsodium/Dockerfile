FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      build-essential \
      ca-certificates \
      curvedns \
      fastd \
      libtoxcore-dev \
      libsodium-dev \
      libzmq3-dev \
      minisign \
      nix-bin \
      php8.3-cli \
      pkg-config \
      python3 \
      python3-nacl \
      r-base-core \
      r-cran-sodium \
      ruby \
      ruby-rbnacl \
      vim \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libsodium/ /validator/tests/libsodium/

RUN chmod +x \
    /validator/tests/_shared/install_safe_debs.sh \
    /validator/tests/_shared/run_library_tests.sh \
    /validator/tests/libsodium/docker-entrypoint.sh \
    /validator/tests/libsodium/tests/run.sh
