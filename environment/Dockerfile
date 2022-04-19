FROM amazonlinux:2022

RUN yum install -y curl findutils aws-cli && \
    yum clean all

ADD install-tools.sh /tmp/install-tools.sh

ADD vendir.yml vendir.lock.yml ./

RUN chmod +x /tmp/install-tools.sh && /tmp/install-tools.sh