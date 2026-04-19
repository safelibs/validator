FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libjpeg-turbo8 \
      libjpeg-turbo8-dev \
      libturbojpeg \
      libturbojpeg0-dev \
      libjpeg-turbo-progs \
      bash \
      build-essential \
      ca-certificates \
      cmake \
      coreutils \
      default-jre-headless \
      file \
      jq \
      pkg-config \
      python3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY libjpeg-turbo/ /validator/tests/libjpeg-turbo/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/libjpeg-turbo/docker-entrypoint.sh /validator/tests/libjpeg-turbo/tests/run.sh \
 && if [ -d /validator/tests/libjpeg-turbo/tests/cases ]; then \
      find /validator/tests/libjpeg-turbo/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
