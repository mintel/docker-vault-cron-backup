FROM alpine:3.9
LABEL maintainer="Francesco Ciocchetti <fciocchetti@mintel.com>"

ENV VAULT_VERSION="1.1.3" \
    VAULT_SHA512="e1dabf807d6eed97df3d71f36e8237d722fa99b3a22f7c88f92b13c9be2843d5733ab1da02ea41a9f7f5b71f991ecf5eba3cc416925feec15fa72ec0217ff50a" \
    SUPERCRONIC_VERSION="0.1.9" \
    SUPERCRONIC_SHA512="a1678fcec4182b675c48296cbfc0866a97a737c4ce1b7b59ad36b3cb587d47fa9c7141e9cba07837579605631bc1b0e15afaabb87d26f8b6571a788713896796"
    


# Install the restic and vault
RUN apk update \
  && apk --no-cache add ca-certificates wget bash jq \
  && wget -O /usr/local/share/ca-certificates/fakelerootx1.crt https://letsencrypt.org/certs/fakelerootx1.pem \
  && wget -O /usr/local/share/ca-certificates/fakeleintermediatex1.crt https://letsencrypt.org/certs/fakeleintermediatex1.pem \
  && update-ca-certificates \
  && wget -O /tmp/vault-${VAULT_VERSION}.zip "https://releases.hashicorp.com/vault/${VAULT_VERSION}/vault_${VAULT_VERSION}_linux_amd64.zip" \
  && wget -O /tmp/supercronic "https://github.com/aptible/supercronic/releases/download/v${SUPERCRONIC_VERSION}/supercronic-linux-amd64" \
  && cd /tmp \
  && echo "${VAULT_SHA512}  vault-${VAULT_VERSION}.zip" | sha512sum -c - \
  && echo "${SUPERCRONIC_SHA512}  supercronic" | sha512sum -c - \
  && unzip -o /tmp/vault-${VAULT_VERSION}.zip -d /usr/local/bin/ \
  && rm /tmp/vault-${VAULT_VERSION}.zip \
  && chmod a+x supercronic \
  && mv supercronic /usr/local/bin \
  && rm -rf /var/cache/apk/*

ADD crontabs/* /etc/crontabs/
ADD bin/* /usr/local/bin/

RUN adduser -D -s /bin/bash mintel
USER mintel

ENTRYPOINT ["/usr/local/bin/supercronic"]
CMD ["/etc/crontabs/crontab"]

