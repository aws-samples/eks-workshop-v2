FROM public.ecr.aws/amazonlinux/amazonlinux:2

ADD installer.sh /installer.sh

RUN bash installer.sh

ADD entrypoint.sh /entrypoint.sh

RUN useradd \
    --home "/learner" \
    --create-home \
    --user-group \
    --shell /bin/bash \
    learner && \
    mkdir /workspace

USER learner

WORKDIR /workspace
COPY --chmod=755 bin/* /usr/local/bin
ADD --chown=learner:learner workspace /workspace/

ENTRYPOINT ["bash", "/entrypoint.sh"]
