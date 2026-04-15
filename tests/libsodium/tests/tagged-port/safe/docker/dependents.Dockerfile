FROM ubuntu:24.04

ARG DEBIAN_FRONTEND=noninteractive
ENV PATH=/root/.cargo/bin:${PATH}

SHELL ["/bin/bash", "-o", "pipefail", "-c"]

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      autoconf \
      automake \
      build-essential \
      ca-certificates \
      cargo \
      curl \
      curvedns \
      debhelper \
      dpkg-dev \
      fakeroot \
      fastd \
      jq \
      librust-libc-dev \
      librust-libsodium-sys-dev \
      librust-pkg-config-dev \
      libtool \
      libsodium-dev \
      libsodium23 \
      libtoxcore-dev \
      libzmq3-dev \
      minisign \
      netcat-openbsd \
      nix-bin \
      php8.3-cli \
      pkg-config \
      python3 \
      python3-nacl \
      qtox \
      r-base-core \
      r-cran-sodium \
      rustc \
      ruby \
      ruby-rbnacl \
      shadowsocks-libev \
      vim \
 && curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs \
      | sh -s -- -y --profile minimal --default-toolchain stable \
 && rm -rf /var/lib/apt/lists/*
