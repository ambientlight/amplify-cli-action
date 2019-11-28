#!/bin/bash -l

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

# if amplify if available at path and custom amplify version is unspecified, do nothing, 
# otherwise install globally latest npm version
# FIXME: weird: using local dep amplify-cli bugs with awscloudformation provider: with using provider underfined
if [ -z $(which amplify) ] || [ -n "$8" ] ; then
  echo "Installing amplify globaly"
  npm install -g @aws-amplify/cli@${8}
# elif [ ! -f ./node_modules/.bin/amplify ] ; then
else
  echo "using amplify available at PATH"
# else 
#   echo "using local project dependency amplify"
#   PATH="$PATH:$(pwd)/node_modules/.bin"
fi

which amplify
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
    echo '{"projectPath": "'"$(pwd)"'","defaultEditor":"code","envName":"'$6'"}' > ./amplify/.config/local-env-info.json

    # if environment doesn't exist fail explicitly
    if [ -z "$(amplify env get --name $6 | grep 'No environment found')" ] ; then  
      echo "found existing environment $6"
      amplify env pull --yes
    else
      echo "$6 environment does not exist, consider using add_env command instead";
      exit 1
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

    amplify env add --amplify "$AMPLIFY" --providers "$PROVIDERS" --yes
    amplify status
    ;;

  delete_env)
    # ACCIDENTAL DELETION PROTECTION #0: delete_lock
    if [ "$7" = true ] ; then
      echo "ACCIDENTAL DELETION PROTECTION: You must unset delete_lock input parameter for delete to work"
      exit 1
    fi

    # ACCIDENTAL DELETION PROTECTION #1: environment to be deleted cannot contain prod/release/master in its name
    if [[ ${6,,} =~ prod|release|master ]] ; then
      echo "ACCIDENTAL DELETION PROTECTION: delete command is unsupported for environments that contain prod/release/master in its name"
      exit 1
    fi

    # fill in dummy env in local-env-info so we delete current environment
    # without switch to another one (amplify restriction) 
    echo '{"projectPath": "'"$(pwd)"'","defaultEditor":"code","envName":"dummyenvfordeletecurrentowork"}' > ./amplify/.config/local-env-info.json
    echo "Y" | amplify env remove "$6"
    ;;

  *)
    echo "amplify command $5 is invalid or not supported"
    exit 1
    ;;
esac
