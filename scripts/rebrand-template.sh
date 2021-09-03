#!/usr/bin/env bash

echo "* Start rebranding"

function sedi() {
    if [[ "$OSTYPE" == "darwin"* ]]; then
        sed -i '' "${1}" "${2}"
    else
        sed -i "${1}" "${2}"
    fi
}

# Go to project base
cd $( cd "$(dirname "${BASH_SOURCE[0]}")" ; pwd -P )/../

readonly BASE_GIT_PATH="Home24/GoService-Template"
readonly BASE_REPO_NAME=${BASE_GIT_PATH##*/}
readonly BASE_GIT_PATH_L=$(echo "${BASE_GIT_PATH}" | tr '[:upper:]' '[:lower:]')
readonly BASE_REPO_NAME_L=$(echo "${BASE_REPO_NAME}" | tr '[:upper:]' '[:lower:]')

readonly README_FILE="README.md"
readonly DEPLOY_MD_FILE="docs/deploy.md"
readonly CIRCLE_CONFIG_FILE=".circleci/config.yml"
readonly MAKE_FILE="Makefile"
readonly DCS_FILE="dcs.yml"
readonly DOCKER_COMPOSE_FILE="docker-compose.yml"
readonly SERVICE_PARAMETERS_STAGING_FILE="infrastructure/staging/service-parameters.yml"
readonly SERVICE_PARAMETERS_PRODUCTION_FILE="infrastructure/production/service-parameters.yml"

readonly GIT_URL=$(git config --get remote.origin.url)
if [[ "${GIT_URL}" == "" ]]; then
    echo "Git project should have remote origin"
    exit 1
fi

readonly GIT_REPO="Home24/"$(echo ${GIT_URL##*Home24/})

readonly GIT_PATH=${GIT_REPO%.git}
readonly REPO_NAME=${GIT_PATH##*/}

readonly GIT_PATH_L=$(echo "${GIT_PATH}" | tr '[:upper:]' '[:lower:]')
readonly REPO_NAME_L=$(echo "${REPO_NAME}" | tr '[:upper:]' '[:lower:]')

echo "* Rebranding from GoService-Template to $REPO_NAME"

# README change
echo " * Rebranding $README_FILE"
sedi "s#${BASE_GIT_PATH}#${GIT_PATH}#g" ${README_FILE}
sedi "s#${BASE_REPO_NAME_L}#${REPO_NAME_L}#g" ${README_FILE}
sedi "s#${BASE_REPO_NAME}#${REPO_NAME}#g" ${README_FILE}

# deploy.md change
echo " * Rebranding $DEPLOY_MD_FILE"
sedi "s#${BASE_REPO_NAME_L}#${REPO_NAME_L}#g" ${DEPLOY_MD_FILE}

# Go file changes
echo " * Rebranding Go paths:"
GO_FILES=($(grep -R "Home24/GoService-Template" * | cut -d':' -f1 | egrep ".go$|.mod$" | uniq))
for i in "${GO_FILES[@]}"
do
    echo "   Rebranding go ${i}"
    sedi "s#${BASE_GIT_PATH}#${GIT_PATH}#g" ${i}
done

# Circle config
echo " * Rebranding $CIRCLE_CONFIG_FILE"
sedi "s#${BASE_GIT_PATH_L}#${GIT_PATH_L}#g" ${CIRCLE_CONFIG_FILE}

# Makefile
echo " * Rebranding $MAKE_FILE"
sedi "s#${BASE_GIT_PATH_L}#${GIT_PATH_L}#g" ${MAKE_FILE}

# dcs.yml
echo " * Rebranding $DCS_FILE"
sedi " s#${BASE_REPO_NAME_L}#${REPO_NAME_L}#g" ${DCS_FILE}
sedi " s#${BASE_REPO_NAME}#${REPO_NAME}#g" ${DCS_FILE}

# docker-compose.yml
echo " * Rebranding $DOCKER_COMPOSE_FILE"
sedi "s#${BASE_GIT_PATH_L}#${GIT_PATH_L}#g" ${DOCKER_COMPOSE_FILE}
sedi "s#${BASE_REPO_NAME_L}#${REPO_NAME_L}#g" ${DOCKER_COMPOSE_FILE}

# infrastructure/staging/service-parameters.yml
echo " * Rebranding $SERVICE_PARAMETERS_STAGING_FILE"
sedi "s#${BASE_REPO_NAME_L}#${REPO_NAME_L}#g" ${SERVICE_PARAMETERS_STAGING_FILE}
sedi "s#${BASE_REPO_NAME}#${REPO_NAME}#g" ${SERVICE_PARAMETERS_STAGING_FILE}

# infrastructure/production/service-parameters.yml
echo " * Rebranding $SERVICE_PARAMETERS_PRODUCTION_FILE"
sedi "s#${BASE_REPO_NAME_L}#${REPO_NAME_L}#g" ${SERVICE_PARAMETERS_PRODUCTION_FILE}
sedi "s#${BASE_REPO_NAME}#${REPO_NAME}#g" ${SERVICE_PARAMETERS_PRODUCTION_FILE}

echo ""
echo ""
echo "* Repository successfully rebranded to $REPO_NAME."
echo ""
echo "You can commit the changes."
echo ""
echo "This script is no longer useful. You can remove it:"
echo "  rm $BASH_SOURCE"
