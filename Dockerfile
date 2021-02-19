FROM ubuntu:16.04
LABEL maintainer="Victor Larodiel"

# Install base dependencies
RUN apt-get update && apt-get upgrade \
    && apt-get install -y \
        software-properties-common \
        build-essential \
        wget \
        xvfb \
        curl \
        git \
        mercurial \
        maven \
        openjdk-8-jdk \
        ant \
        ssh-client \
        unzip \
        iputils-ping \
        php \
        php-xmlwriter \
        php-simplexml \
        npm \
    && rm -rf /var/lib/apt/lists/*

#install PHP code sniffer\
RUN set -eux \
	&& git clone https://github.com/squizlabs/PHP_CodeSniffer

ARG PHPCS
RUN set -eux \
	&& cd PHP_CodeSniffer \
	&& curl -sS -L https://github.com/squizlabs/PHP_CodeSniffer/releases/latest/download/phpcs.phar -o /phpcs.phar \
	&& chmod +x /phpcs.phar \
	&& mv /phpcs.phar /usr/bin/phpcs

# Install nvm with node and npm
ENV NODE_VERSION=14.15.5 \
    NVM_DIR=/root/.nvm \
    NVM_VERSION=0.33.8

RUN curl https://raw.githubusercontent.com/creationix/nvm/v$NVM_VERSION/install.sh | bash \
    && . $NVM_DIR/nvm.sh \
    && nvm install $NODE_VERSION \
    && nvm alias default $NODE_VERSION \
    && nvm use default

RUN export NVM_DIR="/root/.nvm"

# Set node path
ENV NODE_PATH=$NVM_DIR/v$NODE_VERSION/lib/node_modules

RUN npm install --global yarn

RUN php -v \
    node -v \
    yarn -v \
    npm -v

ENV JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64

# Default to UTF-8 file.encoding
ENV LANG=C.UTF-8 \
    LC_ALL=C.UTF-8 \
    LANGUAGE=C.UTF-8

# Xvfb provide an in-memory X-session for tests that require a GUI
ENV DISPLAY=:99

# Set the path.
ENV PATH=$NVM_DIR:$NVM_DIR/versions/node/v$NODE_VERSION/bin:$PATH

# Create dirs and users
RUN mkdir -p /opt/atlassian/bitbucketci/agent/build \
    && sed -i '/[ -z \"PS1\" ] && return/a\\ncase $- in\n*i*) ;;\n*) return;;\nesac' /root/.bashrc \
    && useradd --create-home --shell /bin/bash --uid 1000 pipelines

WORKDIR /opt/atlassian/bitbucketci/agent/build
ENTRYPOINT /bin/bash