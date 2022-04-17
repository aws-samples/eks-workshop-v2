FROM environment

RUN yum install -y nodejs npm aws-cli procps

RUN npm install -g @niallthomson/wtf@0.0.13

COPY run.sh /

ENTRYPOINT ["bash", "/run.sh"]