FROM docker.io/steamcmd/steamcmd:ubuntu-22 as downloader

WORKDIR /dist

RUN steamcmd +force_install_dir /dist +login anonymous +app_update 380870 validate +quit


FROM docker.io/ubuntu:22.10 as cert-builder

# Server needs SSL certs, this is the best way to do that.
RUN apt update -qq && \
	apt install -yqq ca-certificates && \
	update-ca-certificates


# lean runtime
FROM docker.io/ubuntu:22.10
COPY --from=cert-builder /etc/ssl/certs /etc/ssl/certs
RUN adduser --disabled-login pz
USER pz

COPY --chown=pz --from=downloader /dist /pz

ENTRYPOINT ["sh", "/pz/start-server.sh"]
