FROM eks-workshop-environment

USER root

RUN yum install -y nodejs npm aws-cli procps

RUN npm install -g @niallthomson/markdown-sh@0.3.0

COPY run.sh /

USER learner

ENTRYPOINT ["bash", "-l", "/run.sh"]