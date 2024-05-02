FROM restic/restic:0.16.4

ARG TARGETARCH=amd64

ARG IMAGE_VERSION=latest

ENV IMAGE_VERSION ${IMAGE_VERSION}
ENV RESTIC_REPOSITORY "/repo"
ENV RESTIC_PASSWORD ""
ENV BACKUP_CRON "00 */24 * * *"
ENV CHECK_CRON "00 04 * * 1"
ENV BACKUP_SOURCE "/data"
ENV RESTIC_FORGET_ARGS "--keep-last 7"
ENV NICE_ADJUST "10"
ENV IONICE_CLASS "2"
ENV IONICE_PRIO "7"
ENV RESTIC_PASSWORD "default_for_tests"
ENV RESTIC_DATA_DIR "/data"
ENV RESTIC_RESTORE "0"
ENV RESTIC_RESTORE_SNAPSHOT "latest"
ENV RESTIC_BACKUP_ON_EXIT "1"
ENV RESTIC_INSTANT_BACKUP "0"
ENV REFRESH_INTERVAL "600"
ENV RESTIC_SCRIPTS_DIR "/restic-scripts"
ENV RESTIC_MARKER_FILE_SUBDIR "/"

WORKDIR /

RUN apk add py3-pip curl mysql-client mariadb-connector-c --no-cache

# ##versions: https://raw.githubusercontent.com/ngosang/restic-exporter
ARG RESTIC_EXPORTER_VERSION=1.5.0
RUN set -e; \
  mkdir /exporter; \
  cd /exporter; \
  python3 -m venv ./venv; \
  . ./venv/bin/activate; \
  wget -q https://raw.githubusercontent.com/ngosang/restic-exporter/${RESTIC_EXPORTER_VERSION}/requirements.txt; \
  pip3 install -r requirements.txt; \
  wget -q https://raw.githubusercontent.com/ngosang/restic-exporter/${RESTIC_EXPORTER_VERSION}/restic-exporter.py;

# ##versions: https://github.com/kubernetes/kubernetes/releases
ARG KUBECTL_VERSION=1.29.4
RUN set -e; \
    cd /tmp; \
    curl -sLO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl"; \
    mv kubectl /usr/local/bin/; \
    chmod +x /usr/local/bin/kubectl

ADD scripts/* /

ENTRYPOINT ["/entry.sh"]
