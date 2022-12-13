FROM eks-workshop-environment

USER root

RUN curl -sL https://rpm.nodesource.com/setup_16.x | bash - && \
    yum install -y nodejs npm aws-cli procps && \
    yum clean all

WORKDIR /app

COPY util/package.json .
COPY util/package-lock.json .

RUN npm ci

COPY util/ /app/
RUN npm run build

COPY run.sh /

USER learner

ENTRYPOINT ["bash", "-l", "/run.sh"]
