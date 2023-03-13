FROM public.ecr.aws/amazonlinux/amazonlinux:2

ADD scripts/installer.sh /tmp/installer.sh

RUN bash /tmp/installer.sh

RUN useradd \
    --home "/home/ec2-user" \
    --create-home \
    --user-group \
    --shell /bin/bash \
    ec2-user

COPY --chmod=755 bin/* /usr/local/bin

USER ec2-user

COPY --chmod=755 scripts/setup.sh /tmp/setup.sh

RUN bash /tmp/setup.sh

RUN mkdir -p ~/environment

WORKDIR /home/ec2-user/environment
