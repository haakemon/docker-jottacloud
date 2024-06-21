FROM ubuntu:24.04@sha256:2e863c44b718727c860746568e1d54afd13b2fa71b160f5cd9058fc436217b30

VOLUME [ "/data" ]

ENV JOTTA_TOKEN="" \
  JOTTA_DEVICE="docker-jottacloud" \
  JOTTA_SCANINTERVAL="12h" \
  GLOBAL_IGNORE="" \
  STARTUP_TIMEOUT=15 \
  JOTTAD_SYSTEMD=0

RUN apt-get update -y \
  && apt-get upgrade -y \
  && apt-get -y install expect \
  && apt-get -y install curl apt-transport-https ca-certificates \
  && curl -fsSL https://repo.jotta.us/public.asc -o /usr/share/keyrings/jotta.gpg \
  && echo "deb [signed-by=/usr/share/keyrings/jotta.gpg] https://repo.jotta.us/debian debian main" | tee /etc/apt/sources.list.d/jotta-cli.list \
  && apt-get update -y \
  && apt-get install -y jotta-cli=0.15.98319 \
  && apt-get autoremove -y --purge \
  && apt-get clean \
  && rm -rf /var/lib/lists/*

COPY entrypoint.sh /src/
WORKDIR /src
RUN chmod +x entrypoint.sh

EXPOSE 14443

ENTRYPOINT [ "/src/entrypoint.sh" ]
