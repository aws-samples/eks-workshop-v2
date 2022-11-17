FROM public.ecr.aws/amazonlinux/amazonlinux:2

ADD installer.sh /installer.sh

RUN bash installer.sh

ADD entrypoint.sh /entrypoint.sh

RUN useradd \
    --home "/learner" \
    --create-home \
    --user-group \
    --shell /bin/zsh \
    learner && \
    mkdir /workspace

USER learner

RUN wget https://github.com/robbyrussell/oh-my-zsh/raw/master/tools/install.sh -O - | zsh

WORKDIR /workspace
COPY --chmod=755 bin/* /usr/local/bin
ADD --chown=learner:learner workspace /workspace/

ENTRYPOINT ["bash", "/entrypoint.sh"]
