#!/bin/sh -l

set -e

if [ -z "$AWS_ACCESS_KEY_ID" ] && [ -z "$AWS_SECRET_ACCESS_KEY" ] ; then
  echo "You must provide the action with both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables in order to deploy"
  exit 1
fi

if [ -z "$AWS_DEFAULT_REGION" ] ; then
  echo "You must provide AWS_DEFAULT_REGION environment variable in order to deploy"
  exit 1
fi

if [ -z "$6" ] ; then
  echo "You must provide amplify_env input parameter in order to deploy"
  exit 1
fi

# cd to project_dir if custom subfolder is specified
if [ -n "$1" ] ; then
  cd "$1"
fi

# should_skip_npm_install
if [ "$5" = false ] ; then
  npm install
fi

# if amplify-cli is not installed as project local dependency, install globally latest npm version
if [ ! -f ./node_modules/.bin/amplify ]; then
  npm install -g @aws-amplify/cli
else 
  PATH="$PATH:$(pwd)/node_modules/.bin"
fi

FRONTENDCONFIG="{\
\"SourceDir\":\"$2\",\
\"DistributionDir\":\"$3\",\
\"BuildCommand\":\"$4\",\
\"StartCommand\":\"npm run-script start\"\
}"

AWSCLOUDFORMATIONCONFIG="{\
\"configLevel\":\"project\",\
\"useProfile\":true,\
\"profileName\":\"default\",\
\"accessKeyId\":\"$AWS_ACCESS_KEY_ID\",\
\"secretAccessKey\":\"$AWS_SECRET_ACCESS_KEY\",\
\"region\":\"$AWS_REGION\"\
}"

AMPLIFY="{\
\"projectName\":\"github actions CI\",\
\"defaultEditor\":\"code\"\
}"

FRONTEND="{\
\"frontend\":\"javascript\",\
\"framework\":\"none\",\
\"config\":$FRONTENDCONFIG\
}"

PROVIDERS="{\
\"awscloudformation\":$AWSCLOUDFORMATIONCONFIG\
}"

# this is required in addition to configure project for env to work
echo '{"projectPath": "'"$(pwd)"'","defaultEditor":"code","envName":"'$6'"}' > ./amplify/.config/local-env-info.json

amplify configure project \
--amplify "$AMPLIFY" \
--frontend "$FRONTEND" \
--providers "$PROVIDERS" \

amplify env pull --yes
amplify status