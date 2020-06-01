FROM docker.infra.tstllc.net/lib/vault-python
MAINTAINER David Cox <david.cox@tstllc.net>

RUN apk --no-cache add gnupg

RUN pip install python-gnupg requests ruamel.yaml

WORKDIR /opt/vault-infra

COPY ./ /opt/vault-infra/

ENTRYPOINT ["/opt/vault-infra/vadmin" ]
