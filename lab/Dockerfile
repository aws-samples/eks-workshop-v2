FROM public.ecr.aws/amazonlinux/amazonlinux:2023

RUN yum install -y --allowerasing tar gzip vi shadow-utils sudo curl && useradd \
    --home "/home/ec2-user" \
    --create-home \
    --user-group \
    --shell /bin/bash \
    ec2-user

RUN echo "ec2-user ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers

# Install mise to a system-wide location accessible to all users
# renovate: depName=jdx/mise
ARG MISE_VERSION="2026.4.18"
RUN curl -fsSL "https://github.com/jdx/mise/releases/download/v${MISE_VERSION}/install.sh" | \
    MISE_INSTALL_PATH=/usr/local/bin/mise sh
ENV PATH="/usr/local/bin:$PATH"

# Configure mise for system-wide tool installation
ENV MISE_DATA_DIR="/usr/local/share/mise"
ENV MISE_CACHE_DIR="/usr/local/share/mise/cache"

# Make mise shims available to all users at runtime
ENV PATH="/usr/local/share/mise/shims:$PATH"

COPY mise.toml /tmp/mise.toml
RUN mise trust /tmp/mise.toml && \
    mise install --cd /tmp && \
    # Place global tool config in ec2-user home — runtime user in this container
    mkdir -p /home/ec2-user/.config/mise && \
    cp /tmp/mise.toml /home/ec2-user/.config/mise/config.toml && \
    chown -R ec2-user:ec2-user /home/ec2-user/.config && \
    chmod -R 755 /usr/local/share/mise && \
    # Allow ec2-user to write mise cache at runtime
    chown -R ec2-user:ec2-user /usr/local/share/mise/cache

ADD scripts/installer.sh /tmp/installer.sh

RUN bash /tmp/installer.sh

COPY scripts/code-server.sh /tmp/code-server.sh

RUN bash /tmp/code-server.sh

COPY --chmod=755 scripts/entrypoint.sh /entrypoint.sh

COPY --chmod=755 bin/* /usr/local/bin

RUN mkdir -p /eks-workshop && chown ec2-user /eks-workshop

USER ec2-user

COPY --chmod=755 scripts/setup.sh /tmp/setup.sh
COPY --chmod=755 scripts/setup-ide.sh /tmp/setup-ide.sh

RUN mkdir -p ~/environment

WORKDIR /home/ec2-user/environment

ENTRYPOINT ["/entrypoint.sh"]
