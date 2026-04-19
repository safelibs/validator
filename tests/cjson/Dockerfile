FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update \
 && apt-get install -y --no-install-recommends \
      libcjson1 \
      libcjson-dev \
      iperf3 \
      mosquitto-clients \
      bash \
      build-essential \
      ca-certificates \
      coreutils \
      file \
      jq \
      pkg-config \
      python3 \
 && rm -rf /var/lib/apt/lists/*

WORKDIR /validator

COPY _shared/ /validator/tests/_shared/
COPY cjson/ /validator/tests/cjson/

RUN find /validator/tests/_shared -maxdepth 1 -type f -name '*.sh' -exec chmod +x {} + \
 && chmod +x /validator/tests/cjson/docker-entrypoint.sh /validator/tests/cjson/tests/run.sh \
 && if [ -d /validator/tests/cjson/tests/cases ]; then \
      find /validator/tests/cjson/tests/cases -type f -name '*.sh' -exec chmod +x {} +; \
    fi
