FROM amazonlinux:2022

ARG GITHUB_TOKEN=''

RUN yum install -y curl findutils aws-cli jq && \
    yum clean all

ADD install-tools.sh /tmp/install-tools.sh

ADD entrypoint.sh /entrypoint.sh

ADD vendir.* ./

RUN chmod +x /tmp/install-tools.sh && VENDIR_GITHUB_API_TOKEN=$GITHUB_TOKEN /tmp/install-tools.sh && rm -f /tmp/install-tools.sh

ENTRYPOINT ["bash", "/entrypoint.sh"]