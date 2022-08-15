FROM amazonlinux:latest

RUN yum install -y findutils aws-cli jq tar gzip && \
    yum clean all

RUN curl -LO https://dl.k8s.io/release/v1.22.12/bin/linux/amd64/kubectl && \
  chmod +x ./kubectl && \
  mv ./kubectl /usr/local/bin

RUN curl -fsSL -o helm.tar.gz https://get.helm.sh/helm-v3.9.2-linux-amd64.tar.gz && \
  tar zxf helm.tar.gz && \
  chmod +x linux-amd64/helm && \
  mv ./linux-amd64/helm /usr/local/bin && \
  rm -rf linux-amd64/ helm.tar.gz

ADD entrypoint.sh /entrypoint.sh

ENTRYPOINT ["bash", "/entrypoint.sh"]