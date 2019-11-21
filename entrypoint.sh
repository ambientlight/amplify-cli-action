#!/bin/sh -l

set -e

if [ -z "$AWS_ACCESS_KEY_ID" ] && [ -z "$AWS_SECRET_ACCESS_KEY" ] ; then
  echo "You must provide the action with both AWS_ACCESS_KEY_ID and AWS_SECRET_ACCESS_KEY environment variables in order to deploy"
  exit 1
fi

if [ -z "$AWS_REGION" ] ; then
  echo "You must provide AWS_REGION environment variable in order to deploy"
  exit 1
fi

if [ -z "$5" ] ; then
  echo "You must provide amplify_command input parameter in order to deploy"
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

# if amplify if available at path, do nothing, 
# otherwise check if it is not installed as project local dependency, 
# otherwise install globally latest npm version
if [ -x "$(command -v amplify)" ] ; then
  echo "using amplify available at PATH"
elif [ ! -f ./node_modules/.bin/amplify ] ; then
  echo "amplify has not been found at PATH or as local npm dependency. Installing amplify globally..."
  npm install -g @aws-amplify/cli
else 
  echo "using local project dependency amplify"
  PATH="$PATH:$(pwd)/node_modules/.bin"
fi

echo "amplify version $(amplify --version)"

case $5 in

  push)
    amplify push --yes
    ;;

  publish)
    amplify publish --yes
    ;;

  status)
    amplify status
    ;;

  configure)
    FRONTENDCONFIG="{\
    \"SourceDir\":\"$2\",\
    \"DistributionDir\":\"$3\",\
    \"BuildCommand\":\"$4\",\
    \"StartCommand\":\"npm run-script start\"\
    }"

    AWSCLOUDFORMATIONCONFIG="{\
    \"configLevel\":\"project\",\
    \"useProfile\":false,\
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

    amplify configure project --amplify "$AMPLIFY" --frontend "$FRONTEND" --providers "$PROVIDERS" --yes

    # if environment doesn't exist create a new one
    if [[ -z $(amplify env get --name "$6" | grep "No environment found") ]] ; then 
      echo "$6 environment does not yet exist"
    else 
      echo "found existing environment $6"
      amplify env pull --yes
    fi
    
    amplify status
    ;;

  add_env)
    AMPLIFY="{\
    \"envName\":\"$6\"\
    }"

    AWSCLOUDFORMATIONCONFIG="{\
    \"configLevel\":\"project\",\
    \"useProfile\":false,\
    \"accessKeyId\":\"$AWS_ACCESS_KEY_ID\",\
    \"secretAccessKey\":\"$AWS_SECRET_ACCESS_KEY\",\
    \"region\":\"$AWS_REGION\"\
    }"

    PROVIDERS="{\
    \"awscloudformation\":$AWSCLOUDFORMATIONCONFIG\
    }"

    amplify-dev env add --amplify "$AMPLIFY" --providers $PROVIDERS --yes
    amplify status
    ;;

  delete_env)
    # ACCIDENTAL DELETION PROTECTION #0: delete_lock
    if [ "$7" = true ] ; then
      echo "ACCIDENTAL DELETION PROTECTION: You must unset delete_lock input parameter for delete to work"
      exit 1
    fi

    # ACCIDENTAL DELETION PROTECTION #1: environment to be deleted cannot contain prod/release/master in its name
    if [[ "$6" =~ prod|release|master ]] ; then
      echo "ACCIDENTAL DELETION PROTECTION: delete command is unsupported for environments that contain prod/release/master in its name"
      exit 1
    fi

    echo "Y" | amplify env remove "$6"
    ;;

  *)
    echo "amplify command $5 is invalid or not supported"
    exit 1
    ;;
esac