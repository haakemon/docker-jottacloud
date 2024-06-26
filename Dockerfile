FROM ubuntu:24.04@sha256:e3f92abc0967a6c19d0dfa2d55838833e947b9d74edbcb0113e48535ad4be12a

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
