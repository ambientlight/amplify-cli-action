# amplify-cli-action [NO LONGER MAINTAINED]

[![RELEASE](https://img.shields.io/github/v/release/ambientlight/amplify-cli-action?include_prereleases)](https://github.com/ambientlight/amplify-cli-action/releases)
[![View Action](https://img.shields.io/badge/view-action-blue.svg?logo=github&color=orange)](https://github.com/marketplace/actions/amplify-cli-action)
[![LICENSE](https://img.shields.io/github/license/ambientlight/amplify-cli-action)](https://github.com/ambientlight/amplify-cli-action/blob/master/LICENSE)
[![ISSUES](https://img.shields.io/github/issues/ambientlight/amplify-cli-action)](https://github.com/ambientlight/amplify-cli-action/issues)

No longer maintained. Feel free to send the PR to **README.md** and link folks to a maintained fork if such exist.  
  
🚀 :octocat: AWS Amplify CLI support for github actions. This action supports configuring and deploying your project to AWS as well as creating and undeploying amplify environments.

## Getting Started
You can include the action in your workflow as `actions/amplify-cli-action@0.3.0`. Example (configuring amplify, building and deploying):

```yaml
name: 'Amplify Deploy'
on: [push]

jobs:
  test:
    name: test amplify-cli-action
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [10.x]

    steps:
    - uses: actions/checkout@v1

    - name: use node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v1
      with:
        node-version: ${{ matrix.node-version }}

    - name: configure amplify
      uses: ambientlight/amplify-cli-action@0.3.0
      with:
        amplify_command: configure
        amplify_env: prod
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_REGION: us-east-1

    - name: install, build and test
      run: |
        npm install
        # build and test
        # npm run build
        # npm run test
    
    - name: deploy
      uses: ambientlight/amplify-cli-action@0.3.0
      with:
        amplify_command: publish
        amplify_env: prod
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_REGION: us-east-1
    
```

## Configuration
You are required to provide `amplify_command` and `amplify_env` input parameters ([with](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions#jobsjob_idstepswith) section of your workflow) as well as AWS credentials and aws region: **AWS_ACCESS_KEY_ID**,  **AWS_SECRET_ACCESS_KEY**, **AWS_REGION** environment variables that should be stored as repo secrets. You can learn more about setting environment variables with Github action [here](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions#jobsjob_idstepsenv).

## AWS Credentials: Controlling Access with IAM
I would personally discourage using `AdministratorAccess` IAM policy or root account credentials for **AWS_ACCESS_KEY_ID**,  **AWS_SECRET_ACCESS_KEY** here. Instead, consider creating a designated AWS IAM user for this step with permissions restricted to AWS resources associated with amplify category resources used. This can get tricky since in addition to AWS CloudFormation permissions, IAM user who creates or delete stacks require additional permissions that depends on the stack templates. For example, if you have a template that describes an Amazon DynamoDB Table (in amplify storage category), IAM user must have the corresponding permissions for Amazon DynamoDB actions to successfully create the stack. Nonetheless, next steps guide you through creation of IAM user for this step.

1. Navigate to [AWS Identity and Access Management console](https://console.aws.amazon.com/iam/home)
2. Under Users -> `Add New User`. Fill in the user name(`GithubCI`) and set `Programmatic Access` for **Access type**.
3. In permissions, select `Create a new group`, in a dropdown select `Create policy`.
4. In a policy creation menu, select `JSON` tab and fill it with a next policy statement, then hit review and save:
  ```json
  {
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "cloudformation:CreateUploadBucket",
                "cloudformation:DescribeStackResource",
                "cloudformation:UpdateStackSet",
                "cloudformation:DescribeStackEvents",
                "cloudformation:UpdateStack",
                "cloudformation:CreateStackSet",
                "cloudformation:DescribeStackResources",
                "cloudformation:DeleteStackSet",
                "cloudformation:DescribeStacks",
                "cloudformation:CreateStack",
                "cloudformation:DeleteStack"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "iam:CreateRole",
                "iam:GetRole",
                "iam:PassRole",
                "iam:PutRolePolicy",
                "iam:GetPolicy",
                "iam:DeleteRole",
                "iam:DeleteRolePolicy",
                "iam:CreatePolicy",
                "iam:UpdateRole",
                "iam:GetRolePolicy"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "s3:CreateBucket",
                "s3:PutObject",
                "s3:GetObject"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "dynamodb:*",
                "cloudfront:*",
                "cognito-identity:*",
                "s3:*",
                "appsync:*",
                "lambda:*",
                "cognito-idp:*"
            ],
            "Resource": "*"
        }
    ]
  }
  ```

  The first 3 policy statement blocks contain neccessary IAM permissions for Amplify CloudFormation deployments to work, while the last one contains permissions corresponding to AWS resources that are commonly used in Amplify (as an example): `auth`, `api`, `hosting`, `storage`, `function`. You will most likely **NEED TO ADD** more permissions corresponding to other resources used in your project. You may further constraint it down to specific service actions, but this can be a bit annoying as it is not clear and obvious what permissions(wasn't able to find cloudformation docs that list permissions needed to create/update/remove resources for given service) you will need for a given amplify category resource, most likely you will find yourself iteratively deploying while tweaking IAM permissions until deployment succeeds.

5. In the previous page group creation dropdown, find a newly created policy in the list, add a name (`AmplifyDeploy`) and click on Create Group.
6. Select a newly created group for this new user, click through the other steps and finish creating a new user.
7. Copy the access key and secret access key into your github repository Secrets (in repo's Settings) as **AWS_ACCESS_KEY_ID**,  **AWS_SECRET_ACCESS_KEY**.
8. You can also learn more at [Controlling Access with AWS Identity and Access Management](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/using-iam-template.html)

## Inputs

### amplify_command

**type**: `string`  
**values**: `configure | push | publish | status | add_env | delete_env`

#### configure
**required parameters**: `amplify_env`

Configures amplify and initializes specified amplify environment, which is required to exist prior to running this command.

#### push

Perform cloudformation deployment of your latest amplify updates. You are required to run this step with `configure` command prior to running this. 

**Note #0:** this won't additionally build and deploy your front-end artifacts. Use [publish](#publish) for this.  
**Note #1:** don't forget to run `amplify env pull` locally to synchronize the stacks status aftwards

#### publish

Perform cloudformation deployment of your latest amplify updates as well as front-end artifacts if hosting category is used in your project. You are required to run this step with `configure` command prior to running this.

**Note:** don't forget to run `amplify env pull` locally to synchronize the stacks status aftwards

#### status

Shows the state of local resources not yet pushed to the cloud (Create/Update/Delete). You are required to run this step with `configure` command prior to running this.

#### add_env
**required parameters**: `amplify_env`

Creates and initialized a new amplify environment. You would likely need this if you want to create a full replica of production environment for running integration tests (Refer to [Replicating Environment for Integration Tests](#replicating-environment-for-integration-tests)). **IMPORTANT**: make sure to always run this step together with [delete_env](#delete_env) command since this new environment won't be added to your project's configuration and you would need to manually delete the leftover cloudformation stack and S3 bucket otherwise.

**Note #0**: you need to specify custom `amplify_cli_version`: `3.17.1-alpha.35` that [fixes headless push](https://github.com/aws-amplify/amplify-cli/pull/2743) bug before `3.17.1` is released.  
**Note #1**: **WILL FAIL** with `resource already exists` exception if you repeatedly populate the environment that you have undeployed previously **WHEN** you are using storage category in your project and its CF `AWS::S3::Bucket` resource has **Retain** `DeletionPolicy`, since `delete_env` step won't remove such S3 bucket.  
**Note #2**: may take significant time if you are utilizing `AWS CloudFront` in your hosting category.

#### delete_env
**required parameters**: `amplify_env, delete_lock`

Undeploys cloudformation stack(removes all resources) for a selected amplify environment. To prevent accidental deletion, you are required to explicitly set [delete_lock](#delete_lock) input parameter with `false`. For the same reason, this step will fail if you try running it on the enivonment with name containing `prod/release/master`. 

**Note #0**: results in leftover amplify environment S3 bucket since `amplify env delete` won't remove this S3 bucket. (this will not affect repeated population of the environment with the same name as new population will create S3 bucket with different name)  
**Note #1**: repeated population of environment with the same name **WILL FAIL** with `resource already exists` exception if you repeatedly populate the environment that you have undeployed previously **WHEN** you are using storage category in your project and its CF `AWS::S3::Bucket` resource has **Retain** `DeletionPolicy`, since `delete_env` step won't remove such S3 bucket.  
**Note #2**: may take significant time if you are utilizing `AWS CloudFront` in your hosting category.

### amplify_env
**type**: `string`  
**required**: `YES` for amplify_commands: `configure, add_env, delete_env`.

Name of amplify environment used in this step.

### amplify_cli_version
**type**: `string`  
**required** `NO`

Use custom amplify version instead of latest stable (npm's `@latest`) when parameter is not specified.

### project_dir
**type**: `string`  
**required**: `NO`

the root amplify project directory (contains `/amplify`): use it if you amplify project is not this repo root directory.

### delete_lock
**type**: `bool`  
**required** `YES` for `delete_env` amplify_command  
**default**: true

deletion protection: explicitly set this to false if you want `delete_env` step to work.

### amplify_arguments
**type**: `string`  
**required** `NO`

additional arguments to pass to ampify_command's defined command

## Advanced Examples

### Replicating environment for integration tests

You may soon find the need of running fully-fledged tests that would test the actual API calls and other functionality available in your infrustructure rather their mocked counterparts. This is achieved in the next example by means of populating the new amplify environment, running all the necessary tests and undeploying amplify environment back. PR branch name is used for environment name. Please note that subsequent commits to PR branch may fail with `resource already exist` if your amplify category resources use [DeletionPolicy](https://docs.aws.amazon.com/AWSCloudFormation/latest/UserGuide/aws-attribute-deletionpolicy.html) in its CF templates that is set to `Retain`.
Also note, each deployment results in leftover amplify environment S3 bucket (named `amplify-{PROJECT_NAME}-{ENV_NAME}-{ID}-deployment`) since `amplify env delete` won't remove this S3 bucket. (this will not affect repeated population of the environment with the same name as new population will create S3 bucket with different name)  

```yaml
name: 'Integration Tests'
on: [pull_request]

jobs:
  test:
    name: test amplify-cli-action
    runs-on: ubuntu-latest

    strategy:
      matrix:
        node-version: [10.x]

    steps:
    - uses: actions/checkout@v1

    - name: use node.js ${{ matrix.node-version }}
      uses: actions/setup-node@v1
      with:
        node-version: ${{ matrix.node-version }}

    - name: set amplify env name
      id: setenvname
      run: |
        # use GITHUB_HEAD_REF that is set to PR source branch
        # also remove -_ from branch name and limit length to 10 for amplify env restriction
        echo "##[set-output name=amplifyenvname;]$(echo ${GITHUB_HEAD_REF//[-_]/} | cut -c-10)"
    - name: deploy test environment
      uses: ambientlight/amplify-cli-action@0.3.0
      with:
        amplify_command: add_env
        amplify_env: ${{ steps.setenvname.outputs.amplifyenvname }}
        amplify_cli_version: '3.17.1-alpha.35'
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_REGION: us-east-1

    - name: install, build and run integration tests
      run: |
        # build and test
        # npm install
        # npm run build
        # npm run test
    
    - name: undeploy test environment
      uses: ambientlight/amplify-cli-action@0.3.0
      # run even if previous step fails
      if: failure() || success()
      with:
        amplify_command: delete_env
        amplify_env: ${{ steps.setenvname.outputs.amplifyenvname }}
        amplify_cli_version: '3.17.1-alpha.35'
        delete_lock: false
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_REGION: us-east-1
    
```

As an alternative, one practical way could be to have a fixed sandbox environment that all PRs will update regardless of the branch (and doesn't get undeployed), so it can be used as a playground to manually test and play around with upcoming updates, but kind in mind there can be potential additional costs involved as some AWS resources used in amplify have fixed by-hours costs (kinesis for example).


## Development

How to roll out a new image

``` bash
VERSION=0.3.0

docker build -t amplify-cli-action:$VERSION .

docker tag amplify-cli-action:$VERSION ghcr.io/ambientlight/amplify-cli-action/amplify-cli-action:$VERSION

docker push ghcr.io/ambientlight/amplify-cli-action/amplify-cli-action:$VERSION

```
