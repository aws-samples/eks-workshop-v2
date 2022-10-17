FROM public.ecr.aws/amazonlinux/amazonlinux:2022

RUN yum install -y findutils aws-cli jq tar gzip zsh git diffutils wget tree && \
    yum clean all

RUN curl -LO https://dl.k8s.io/release/v1.23.9/bin/linux/amd64/kubectl && \
  chmod +x ./kubectl && \
  mv ./kubectl /usr/local/bin

RUN curl -fsSL -o helm.tar.gz https://get.helm.sh/helm-v3.9.2-linux-amd64.tar.gz && \
  tar zxf helm.tar.gz && \
  chmod +x linux-amd64/helm && \
  mv ./linux-amd64/helm /usr/local/bin && \
  rm -rf linux-amd64/ helm.tar.gz
  
RUN curl --location "https://github.com/weaveworks/eksctl/releases/download/v0.114.0/eksctl_Linux_amd64.tar.gz" | tar xz && \
  chmod +x eksctl && \
  mv ./eksctl /usr/local/bin

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