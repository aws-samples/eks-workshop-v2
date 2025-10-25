FROM eks-workshop-environment

USER root

RUN yum install https://rpm.nodesource.com/pub_16.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y && \
    yum install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1

WORKDIR /app

COPY util/package.json .
COPY util/package-lock.json .

RUN npm ci

COPY util/ /app/
RUN npm run build

COPY run.sh /

USER ec2-user

WORKDIR /home/ec2-user/environment

ENTRYPOINT ["bash", "-l", "/run.sh"]
