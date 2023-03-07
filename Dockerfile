FROM docker.io/steamcmd/steamcmd:ubuntu-22 as downloader

WORKDIR /dist

RUN steamcmd +force_install_dir /dist +login anonymous +app_update 380870 validate +quit

FROM docker.io/golang:1.20.1-buster as builder
RUN apt-get update -qq && \
	apt-get install -yqq ca-certificates build-essential git

RUN git clone https://github.com/gorcon/rcon-cli.git

WORKDIR /go/rcon-cli

RUN CGO_ENABLED=1 go build -v ./cmd/gorcon

FROM docker.io/openjdk:17-jdk-slim as cert-builder

# Server needs SSL certs, this is the best way to do that.
RUN apt-get update -qq && \
	apt-get install -yqq ca-certificates && \
	update-ca-certificates
COPY --chown=root --from=builder /go/rcon-cli/gorcon /bin/rcon

RUN chmod +x /bin/rcon

RUN useradd --create-home --home-dir /pz-data pz

USER pz

COPY --chown=pz --from=downloader /dist /pz

ENV INSTDIR="/pz"
#ENV PATH="${INSTDIR}/jre64/bin:$PATH"
ENV LD_LIBRARY_PATH="${INSTDIR}/linux64:${INSTDIR}/natives:${INSTDIR}:${INSTDIR}/jre64/lib/amd64:${LD_LIBRARY_PATH}"
ENV JSIG="libjsig.so"
ENV LD_PRELOAD="${LD_PRELOAD}:${JSIG}"

WORKDIR /pz

EXPOSE 16261/udp 16262/udp

VOLUME /pz-data

ENTRYPOINT ["/pz/ProjectZomboid64"]
