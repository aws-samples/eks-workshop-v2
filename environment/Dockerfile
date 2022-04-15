FROM amazonlinux:2022

RUN yum install -y curl findutils aws-cli && \
    yum clean all

RUN curl -fsSL https://github.com/vmware-tanzu/carvel-vendir/releases/download/v0.26.0/vendir-linux-amd64 -o vendir && \
    echo "98057bf90e09972f156d1c4fbde350e94133bbaf2e25818b007759f5e9c8b197  vendir" | sha256sum --check && \
    chmod +x vendir && mv vendir /usr/bin/vendir

ADD install-tools.sh /tmp/install-tools.sh

ADD vendir.yml vendir.lock.yml .

RUN chmod +x /tmp/install-tools.sh && /tmp/install-tools.sh