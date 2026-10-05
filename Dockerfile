FROM ubuntu:26.04

ARG TARGETARCH=amd64

ARG IMAGE_VERSION=latest

ENV IMAGE_VERSION=${IMAGE_VERSION}
ENV RESTIC_REPOSITORY="/repo"
ENV RESTIC_PASSWORD=""
ENV BACKUP_CRON="00 */24 * * *"
ENV CHECK_CRON="00 04 * * 1"
ENV BACKUP_SOURCE="/data"
ENV RESTIC_FORGET_ARGS="--keep-last 7"
ENV NICE_ADJUST="10"
ENV IONICE_CLASS="2"
ENV IONICE_PRIO="7"
ENV RESTIC_PASSWORD="default_for_tests"
ENV RESTIC_DATA_DIR="/data"
ENV RESTIC_RESTORE="0"
ENV RESTIC_RESTORE_SNAPSHOT="latest"
ENV RESTIC_BACKUP_ON_EXIT="1"
ENV RESTIC_INSTANT_BACKUP="0"
ENV REFRESH_INTERVAL="600"
ENV RESTIC_SCRIPTS_DIR="/restic-scripts"
ENV RESTIC_MARKER_FILE_SUBDIR="/"
ENV RESTIC_BACKUP_OPTIONS=""
ENV RESTIC_RESTORE_OPTIONS=""

WORKDIR /

RUN apt-get update && apt-get install -y \
    python3-pip \
    python3.14-venv \
    wget \
    curl \
    bzip2 \
    mysql-client \
    tini \
    cron \
    influxdb-client \
    && rm -rf /var/lib/apt/lists/*

# ##versions: https://github.com/restic/restic/releases
# restic 0.19.x required: restic-exporter 2.x needs total_blob_count in `restic stats --json`
ARG RESTIC_VERSION=0.19.1
RUN set -e; \
    cd /tmp; \
    wget -qO restic.bz2 "https://github.com/restic/restic/releases/download/v${RESTIC_VERSION}/restic_${RESTIC_VERSION}_linux_${TARGETARCH}.bz2"; \
    bunzip2 -c restic.bz2 > /usr/local/bin/restic; \
    chmod +x /usr/local/bin/restic; \
    rm -f restic.bz2

# ##versions: https://github.com/ngosang/restic-exporter/releases
ARG RESTIC_EXPORTER_VERSION=2.1.2
RUN set -e; \
  mkdir /exporter; \
  cd /exporter; \
  python3 -m venv ./venv; \
  . ./venv/bin/activate; \
  # dependency pinned in upstream pyproject.toml (v2.x has no requirements.txt) ##versions https://github.com/ngosang/restic-exporter/blob/2.1.2/pyproject.toml
  pip3 install prometheus-client==0.25.0; \
  wget -q https://raw.githubusercontent.com/ngosang/restic-exporter/${RESTIC_EXPORTER_VERSION}/exporter/exporter.py; \
  # local patch: restic omits total_blob_count/total_file_count from stats JSON when they are 0 (omitempty),
  # exporter crashes with KeyError on empty repositories until first snapshot exists
  sed -i 's/stats_data\["total_blob_count"\]/stats_data.get("total_blob_count", 0)/; s/stats_data\["total_file_count"\]/stats_data.get("total_file_count", 0)/' exporter.py;

# ##versions: https://github.com/kubernetes/kubernetes/releases
ARG KUBECTL_VERSION=1.37.1
RUN set -e; \
    cd /tmp; \
    curl -sLO "https://dl.k8s.io/release/v${KUBECTL_VERSION}/bin/linux/${TARGETARCH}/kubectl"; \
    mv kubectl /usr/local/bin/; \
    chmod +x /usr/local/bin/kubectl

ADD scripts/* /

ENTRYPOINT ["/usr/bin/tini", "--", "/entry.sh"]
