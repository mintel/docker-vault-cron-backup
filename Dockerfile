FROM mintel/restic-cron:0.1.2

ENV VAULT_VERSION="1.2.3" \
    VAULT_SHA512="d012d9c02339a1a7edd07f9e48d2ce039d182324fb492e340b91d645128ce480b6afabf556c61ef8a73b70172e692dc401123b74aaa4604e02a26ec4eaab308c"

USER root

# Install the restic and vault
RUN wget -O /tmp/vault-${VAULT_VERSION}.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip" \
  && cd /tmp \
  && echo "${VAULT_SHA512}  vault-${VAULT_VERSION}.zip" | sha512sum -c - \
  && unzip -o /tmp/vault-${VAULT_VERSION}.zip -d /usr/local/bin/ \
  && chmod a+x /usr/local/bin/vault

ADD rootfs/ /

USER mintel
RUN mkdir -p /home/mintel/.config/backup/restic/repos \
    && mkdir -p /home/mintel/.config/backup/restic/sets

ENTRYPOINT ["/usr/local/bin/supercronic"]
CMD ["-prometheus-listen-address","0.0.0.0:8888","/etc/crontabs/crontab"]

# In case you want to run this as a Kubernetes Cronjob to make sure only one is running at any time add kubelock
COPY --from=mintel/kubelock:0.0.1 /usr/local/bin/kubelock /usr/local/bin/

ARG BUILD_DATE
ARG VCS_REF

LABEL org.label-schema.build-date=$BUILD_DATE \
      org.label-schema.vcs-ref=$VCS_REF \
      org.label-schema.vcs-url="https://github.com/mintel/docker-vault-cron-backup.git" \
      org.label-schema.schema-version="1.0.0-rc1" \
      org.label-schema.name="vault-cron-backup" \
      org.label-schema.description="An image to perform Vault Data backups from a GCS storage backend to a RESTIC backend" \
      org.label-schema.vendor="Mintel LTD" \
      maintainer="Francesco Ciocchetti <fciocchetti@mintel.com>"

