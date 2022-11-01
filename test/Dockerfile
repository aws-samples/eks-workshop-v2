FROM eks-workshop-environment

USER root

RUN curl -sL https://rpm.nodesource.com/setup_16.x | bash - && \
    yum install -y nodejs npm aws-cli procps && \
    yum clean all

RUN npm install -g @niallthomson/markdown-sh@0.3.0

COPY run.sh /

USER learner

ENTRYPOINT ["bash", "-l", "/run.sh"]
