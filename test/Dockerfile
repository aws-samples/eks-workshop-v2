FROM environment

RUN yum install -y nodejs npm aws-cli

RUN npm install -g @niallthomson/wtf@0.0.12

COPY run.sh /

RUN chmod +x /run.sh

ENTRYPOINT ["/run.sh"]