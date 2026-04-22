FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libglib2.0-0t64 \
      libglib2.0-bin \
      libglib2.0-dev \
      libglib2.0-dev-bin \
      libglib2.0-data \
      libgirepository-2.0-0 \
      libgirepository-2.0-dev \
      gir1.2-glib-2.0 \
      gir1.2-glib-2.0-dev \
      gir1.2-girepository-3.0 \
      gir1.2-girepository-3.0-dev \
      python3-gi \
      bash \
      build-essential \
      coreutils \
      pkg-config \
      python3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY glib/ /validator/tests/glib/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/glib/docker-entrypoint.sh \
 && find /validator/tests/glib/tests/cases -type f -name '*.sh' -exec chmod +x {} +
