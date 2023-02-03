FROM node:lts

LABEL "com.github.actions.name"="GitHub action for deploying AWS Amplify project"
LABEL "com.github.actions.description"="This action builds and deploys your AWS Amplify project"
LABEL "com.github.actions.icon"="git-commit"
LABEL "com.github.actions.color"="orange"

LABEL "repository"="https://github.com/ambientlight/amplify-cli-action"
LABEL "homepage"="https://github.com/ambientlight/amplify-cli-action.git"

LABEL org.opencontainers.image.source=https://github.com/ambientlight/amplify-cli-action

COPY entrypoint.sh /entrypoint.sh
ENTRYPOINT ["/entrypoint.sh"]

