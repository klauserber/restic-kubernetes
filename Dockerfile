FROM restic/restic:0.14.0

ADD scripts/* /

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

ENTRYPOINT ["/entry.sh"]

# CMD is run after entrypoint script finishes setup
# CMD ["tail", "-fn0", "/var/log/cron.log"]

# CMD [ "infinity" ]
