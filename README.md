## amplify-cli-action
🚀 :octocat: AWS Amplify CLI support for github actions. This action supports configuring and deploying your project to AWS as well as creating and undeploying amplify environments.

## Getting Started
You can include the action in your workflow as `actions/amplify-cli-action@v0`. Example (configuring amplify, building and deploying):

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
      uses: ambientlight/amplify-cli-action@v0
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
      uses: ambientlight/amplify-cli-action@v0
      with:
        amplify_command: publish
        amplify_env: prod
      env:
        AWS_ACCESS_KEY_ID: ${{ secrets.AWS_ACCESS_KEY_ID }}
        AWS_SECRET_ACCESS_KEY: ${{ secrets.AWS_SECRET_ACCESS_KEY }}
        AWS_REGION: us-east-1
    
```

## Configuration
You are required to provide `amplify_command` and `amplify_env` input parameters ([with](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions#jobsjob_idstepswith) section of your workflow) as well as **AWS_ACCESS_KEY_ID**,  **AWS_SECRET_ACCESS_KEY**, **AWS_REGION** environment variables that should be stored as repo secrets. You can learn more about setting environment variables with Github action [here](https://help.github.com/en/actions/automating-your-workflow-with-github-actions/workflow-syntax-for-github-actions#jobsjob_idstepsenv).

## Commands

### amplify_command

**type**: `string`  
**values**: `configure | push | publish | status | add_env | delete_env`

#### configure
**required parameters**: `amplify_env`

Configures amplify and initializes selected environment.

#### push

Perform cloudformation deployment of your latest amplify updates. You are required to run this step with `configure` command prior to running this. **Note:** this won't additionally build and deploy your front-end artifacts. Use [publish](#publish) for this.

#### publish

Perform cloudformation deployment of your latest amplify updates as well as front-end artifacts if hosting category is used in your project. You are required to run this step with `configure` command prior to running this.

#### status

Shows the state of local resources not yet pushed to the cloud (Create/Update/Delete). You are required to run this step with `configure` command prior to running this.

#### add_env
**required parameters**: `amplify_env`

Creates and initialized a new amplify environment. You would likely need this if you want to create a full replica of production environment for running integration tests. **IMPORTANT**: make sure to always run this step together with [delete_env](#delete_env) command since this new environment won't be added to your project's configuration and you would need to manually delete the leftover cloudformation stack and S3 bucket otherwise.

**Note #0**: you need to specify custom `amplify_cli_version`: `3.17.1-alpha.35` that [fixes headless push](https://github.com/aws-amplify/amplify-cli/pull/2743) bug before `3.17.1` is released.  
**Note #1**: **WILL FAIL** with `resource already exists` exception if you repeatedly populate the environment that you have undeployed previously **WHEN** you are using storage category in your project and its CF `AWS::S3::Bucket` resource has **Retain** `DeletionPolicy`, since `delete_env` step won't remove such S3 bucket.  
**Note #2**: may take significant time if you are utilizing `AWS CloudFront` in your hosting category.

### delete_env
**required parameters**: `amplify_env, delete_lock`

Undeploys cloudformation stack(removes all resources) for a selected amplify environment. To prevent accidental deletion, you are required to explicitly set `delete_lock` input parameter with `false`. For the same reason, this step will fail if you try running it on the enivonment with name containing `prod/release/master`. 

**Note #0**: results in leftover amplify environment S3 bucket since `amplify env delete` won't remove this S3 bucket. (this will not affect repeated population of the environment with the same name as new population will create an S3 bucket with different name)  
**Note #1**: repeated population of environment with the same name **WILL FAIL** with `resource already exists` exception if you repeatedly populate the environment that you have undeployed previously **WHEN** you are using storage category in your project and its CF `AWS::S3::Bucket` resource has **Retain** `DeletionPolicy`, since `delete_env` step won't remove such S3 bucket.  
**Note #2**: may take significant time if you are utilizing `AWS CloudFront` in your hosting category.

### amplify_env
**type**: `string`  
**required**: `YES` for amplify_commands: `configure, add_env, delete_env`.

Name of amplify environment used in this step.

### amplify_cli_version
**type**: string  
**required** `NO`

Use custom amplify version instead of latest stable (npm's `@latest`) when parameter is not specified.

### project_dir
**type**: string  
**required**: `NO`

the root amplify project directory (contains `/amplify`): use it if you amplify project is not this repo root directory.

### source_dir
**type**: string  
**required**: `NO`  
**default**: **src**

front-end source location where aws_exports.js will be generated

### distribution_dir
**type**: string
**required**: `NO`  
**default**: **dist**

front-end artifacts deployment directory that gets uploaded to S3 during amplify publish if hosting category is used in the project

### build_command
**type**: string  
**required**: `NO`  
**default**: `npm run build`

a build command to run with amplify publish (to build front-end deployment artifacts)

### delete_lock
**type**: bool  
**required** `YES` for `delete_env` amplify_command  
**default**: true

deletion protection: explicitly set this to false if you want amplify delete to work