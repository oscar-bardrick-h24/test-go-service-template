Deployment
==========

 > Note: this doc assumes you are deploying staging. If you are deploying other environment, change staging to other environment

## Prerequisites

Assuming you have installed [`artisan`](https://github.com/Home24/Infrastructure-Artisan)

Assuming you have logged in with [`sso`](https://github.com/Home24/Go-Tools/tree/master/cmd/sso) to correct AWS Account

## Layout

* `infrastructure/` - all infrastructure related configuration / templates
* `infrastructure/staging/` - all infrastructure configuration / templates for staging

### Stacks

There are 2 stacks which need to be deployed for each application to function. Templates and stacks are named accordingly.

* `security` stack - contains security configuration for accessing the application
* `service` stack - contains all application-related configuration like Load Balancer, monitoring, capacity, permissions, etc.

Each stack has the following things:

* template - `infrastructure/service.yml`
* environment specific parameters for template - `infrastructure/staging/service-parameters.yml`
* tags - tagging configuration - `infrastructure/staging/tags.yml`, might be shared for convenience between multiple stacks
* rollback configuration - `infrastructure/staging/service-rollback-config.yml`

# Deploying

If you are only updating the application, please go to Service stack section.

## Security stack

Update parameters in `infrastructure/staging/security-parameters.yml`

Deploy Security stack:

```bash
STACK_SECURITY=goservice-template-security-staging
ENVIRONMENT=staging
artisan deploy "${STACK_SECURITY}" \
    --template-file infrastructure/${ENVIRONMENT}/security.yml \
    --parameters-file infrastructure/${ENVIRONMENT}/security-parameters.yml \
    --tags-file infrastructure/${ENVIRONMENT}/tags.yml \
    --wait-execution=true
```

Security groups created should be copied to `infrastructure/staging/service-parameters.yml` `ALBSecurityGroups`

## Service stack

Update parameters in `infrastructure/*/service-parameters.yml`

:information_source: You may need output values (in parameters) from `security` stack

### Updating service stack (full)

Depending on what you want to do and what state you are in you want to provide different arguments for the update / creation.

* For creating new
  * `DockerImage=home24/infrastructure-templates-hello-service:latest` - use mock image for the initial container
  * `ServiceTaskDesiredCount=1` - number must be between min and max
  * `Release=initial`
* For updating
  * `ServiceTaskDesiredCount=1` - must be provided in case of service recreation (usually when there are major changes to the template or stack creation). Must be between min and max.
  * `DockerImage` - image from ECR repository to use for service. Will update the service to the image if provided. Not providing one will not change the image. Image must be pushed to repository beforehand
  * `Release` - informational argument (in logs, etc) on release. Usually provided together with `DockerImage`

:information_source: Review generated changeset when updating stack (outputed by `artisan`). Usually there should be no replacements except for TaskDefinition. Replacements are sometimes dangerous and may cause production outage of your service.

```bash
STACK_SERVICE=goservice-template-service-staging
ENVIRONMENT=staging
DOCKER_IMAGE=123456789012.dkr.ecr.eu-west-1.amazonaws.com/my-service-staging:deadbeef

artisan deploy "${STACK_SERVICE}" \
    --template-file infrastructure/service.yml \
    --parameters-file infrastructure/${ENVIRONMENT}/service-parameters.yml \
    --tags-file infrastructure/${ENVIRONMENT}/tags.yml \
    --parameter-overrides ServiceTaskDesiredCount=1 \
    --parameter-overrides DockerImage=${DOCKER_IMAGE} \
    --parameter-overrides Release=initial \
    --wait-execution=true
```

### Updating only underlying image (release)

This flow is usually used to deploy new version of the service without actually
changing the underlying service template (which might contain dangerous changes). This is used by CircleCI to do releases.

:information_source: Does not update the template, only the parameters provided


```bash
STACK_SERVICE=goservice-template-service-staging
ENVIRONMENT=staging
ROLLBACK_CONFIG=infrastructure/staging/service-rollback-config.yml
DOCKER_IMAGE=123456789012.dkr.ecr.eu-west-1.amazonaws.com/my-service-staging:deadbeef

artisan deploy "${STACK_SERVICE}" \
    --rollback-config-file="${ROLLBACK_CONFIG}" \
    --parameter-overrides DockerImage=${DOCKER_IMAGE} \
    --parameter-overrides Release=build-123 \
    --wait-execution=true
```

## CircleCI

Replace values with `service` stack output details in [config.yml](../.circleci/config.yml):
 * `<<ADD_ECR_REPOSOTORY_HERE>>`
 * `<<ADD_SERVICE_NAME_HERE>>`

Configure `CircleCI` environment variables using output details of `service` stack:
 * `AWS_ACCESS_KEY_ID_STAGING`
 * `AWS_SECRET_ACCESS_KEY_STAGING`
 * `AWS_ACCESS_KEY_ID_PRODUCTION`
 * `AWS_SECRET_ACCESS_KEY_PRODUCTION`


# Manually pushing ECR image

You may pull the image with `docker pull` instead of building it locally
```
DOCKER_TAG=local-build-15 make build

ECR_DOCKER_IMAGE=123456789012.dkr.ecr.eu-west-1.amazonaws.com/my-service-staging:local-build-15 DOCKER_TAG=local-build-15 make push-ecr
```
