FROM amazonlinux:2022

ARG GITHUB_TOKEN=''

RUN yum install -y findutils aws-cli jq && \
    yum clean all

RUN curl -LO https://dl.k8s.io/release/v1.22.12/bin/linux/amd64/kubectl && \
  chmod +x ./kubectl && \
  mv ./kubectl /usr/local/bin

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["bash", "/entrypoint.sh"]