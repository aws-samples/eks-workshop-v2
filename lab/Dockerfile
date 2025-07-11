FROM public.ecr.aws/amazonlinux/amazonlinux:2023

RUN yum install -y tar gzip vi shadow-utils && useradd \
    --home "/home/ec2-user" \
    --create-home \
    --user-group \
    --shell /bin/bash \
    ec2-user

ADD scripts/installer.sh /tmp/installer.sh

RUN bash /tmp/installer.sh

COPY scripts/code-server.sh /tmp/code-server.sh

RUN bash /tmp/code-server.sh

COPY --chmod=755 scripts/entrypoint.sh /entrypoint.sh

COPY --chmod=755 bin/* /usr/local/bin

RUN mkdir -p /eks-workshop && chown ec2-user /eks-workshop

USER ec2-user

COPY --chmod=755 scripts/setup.sh /tmp/setup.sh

RUN mkdir -p ~/environment

WORKDIR /home/ec2-user/environment

ENTRYPOINT ["/entrypoint.sh"]
