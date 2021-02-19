Image to help the integration between Bitbucket pipeline and sage theme.

The image contains the follow pages

## Ubuntu Packages
- software-properties-common
- build-essential
- wget
- xvfb
- curl
- git
- mercurial
- maven
- openjdk-8-jdk
- ant
- ssh-client
- unzip
- iputils-ping
- php
- npm

## PHP Extensions and Libs
- php-xmlwriter
- php-simplexml
- PHP_CodeSniffer

## NodeJS
- Node 14.15.5
- NVM 0.37.2
- Yarn

## Variables to be set on Bitbucket repository or Environment
- WP_THEME_PATH
- WP_THEME_NAME

- DOCKER_HUB_USERNAME
- DOCKER_HUB_PASSWORD

- SSH_SERVER
- SSH_PATH
- SSH_PORT 

## bitbucket-pipelines.yml
```yml
image: larodiel/bitbucket-sage-deploy:latest

pipelines:
  default:
    - step:
        name: Files Lint
        script:
          - phpcs -n --tab-width=2 --extensions=php --colors --standard=${BITBUCKET_CLONE_DIR}${WP_THEME_PATH}${WP_THEME_NAME}/phpcs.xml ${BITBUCKET_CLONE_DIR}${WP_THEME_PATH}${WP_THEME_NAME}/resources/views
        artifacts: # defining the artifacts to be passed to each future step.
          - /wp-content/themes/${WP_THEME_NAME}/dist/**
    - step:
        name: "Docker Push"
        services:
          - docker
        script: # Modify the commands below to build your repository.
          # Set $DOCKER_HUB_USERNAME and $DOCKER_HUB_PASSWORD as environment variables in repository settings
          # build the Docker image (this will use the Dockerfile in the root of the repo)
          - export IMAGE_NAME=${DOCKER_HUB_USERNAME}/themes:$BITBUCKET_COMMIT
          - docker build -t $IMAGE_NAME .
          # authenticate with the Docker Hub registry
          - docker login --username $DOCKER_HUB_USERNAME --password $DOCKER_HUB_PASSWORD
          # push the new Docker image to the Docker registry
          - docker push $IMAGE_NAME
    - step:
        name: Deploy to Staging
        deployment: staging
        script:
          - echo "Compiling and deploying to staging, it could take a while..."
          - cd ${BITBUCKET_CLONE_DIR}${WP_THEME_PATH}${WP_THEME_NAME}
          - yarn install
          - yarn test
          - yarn build:production
          - pipe: atlassian/rsync-deploy:0.4.4
            variables:
              USER: '${SSH_STG_USER}'
              SERVER: '${SSH_SERVER}'
              REMOTE_PATH: '${SSH_STG_PATH}'
              LOCAL_PATH: '${BITBUCKET_CLONE_DIR}/'
              SSH_PORT: '${SSH_PORT}'
              DEBUG: 'true'
              EXTRA_ARGS: "--exclude=assets/ --exclude=LICENSE --exclude=node_modules  --exclude=README.md --exclude=gulpfile.js --exclude=bower.json --exclude=composer.json"
              DELETE_FLAG: 'false'
    - step:
        name: Deploy to Production
        deployment: production
        trigger: manual
        script:
          - echo "Compiling and deploying to production, it may take a while..."
          - cd ${BITBUCKET_CLONE_DIR}${WP_THEME_PATH}${WP_THEME_NAME}
          - yarn install
          - yarn test
          - yarn build:production
          - pipe: atlassian/rsync-deploy:0.4.4
            variables:
              USER: $SSH_USER
              SERVER: $SSH_SERVER
              REMOTE_PATH: $SSH_PATH
              LOCAL_PATH: '${BITBUCKET_CLONE_DIR}/'
              SSH_PORT: $SSH_PORT
              EXTRA_ARGS: "--exclude=assets/ --exclude=node_modules --exclude=LICENSE --exclude=README.md --exclude=gulpfile.js --exclude=bower.json --exclude=composer.json"
              DELETE_FLAG: 'false'
```
