FROM eks-workshop-environment

USER root

RUN yum install https://rpm.nodesource.com/pub_16.x/nodistro/repo/nodesource-release-nodistro-1.noarch.rpm -y && \
    yum install nodejs -y --setopt=nodesource-nodejs.module_hotfixes=1

# The Argo CD suite mints an API token by signing in to IAM Identity Center with a
# headless browser, because the EKS Capability for Argo CD offers no other
# non-interactive way to authenticate: it has no local accounts, and no EKS API
# issues a token. Only the tests need a browser, so it is installed here rather than
# in the lab image participants run.
#
# Playwright's own `install --with-deps` is apt-based and this image is Amazon Linux,
# so the libraries Chromium links against are listed explicitly. The list is exactly
# what `ldd` reports as missing for the downloaded browser binaries.
ENV PLAYWRIGHT_BROWSERS_PATH=/opt/playwright

RUN yum install -y python3 python3-pip \
      alsa-lib atk at-spi2-atk at-spi2-core cairo cups-libs dbus-libs \
      libX11 libXcomposite libXdamage libXext libXfixes libXrandr \
      libxcb libxkbcommon mesa-libgbm nspr nss nss-util pango systemd-libs && \
    pip3 install --no-cache-dir playwright boto3 && \
    python3 -m playwright install chromium && \
    # Installed as root but the suite runs as ec2-user, so make the browser readable.
    chmod -R a+rX "$PLAYWRIGHT_BROWSERS_PATH" && \
    yum clean all

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
