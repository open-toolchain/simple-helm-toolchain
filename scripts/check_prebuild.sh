#!/bin/bash
# uncomment to debug the script
#set -x

# env
echo "Build environment variables:"
echo "REGISTRY_URL=${REGISTRY_URL}"
echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}"
echo "IMAGE_NAME=${IMAGE_NAME}"
echo "BUILD_NUMBER=${BUILD_NUMBER}"
echo "ARCHIVE_DIR=${ARCHIVE_DIR}"

# Learn more about the available environment variables at:
# https://console.bluemix.net/docs/services/ContinuousDelivery/pipeline_deploy_var.html#deliverypipeline_environment

# To review or change build options use:
# bx cr build --help

echo "=========================================================="
echo "CHECKING DOCKERFILE"
echo "Checking Dockerfile at the repository root"
if [ -f Dockerfile ]; then 
   echo "Dockerfile found"
else
    echo "Dockerfile not found"
    exit 1
fi

echo "Linting Dockerfile"
npm install -g dockerlint
dockerlint -f Dockerfile

echo "=========================================================="
echo "CHECKING HELM CHART"
echo "Checking Helm chart in /chart/${CHART_NAME} folder"
if [ -d ./chart//${CHART_NAME} ]; then
    echo -e "$Helm chart for Kubernetes deployment (/chart/${CHART_NAME}) found."
else 
    echo -e "Helm chart for Kubernetes deployment (/chart/${CHART_NAME}) not found."
    exit 1
fi

echo "Linting Helm Chart"
helm lint ./chart/${CHART_NAME}

echo "=========================================================="
echo "CHECKING REGISTRY current plan and quota"
bx cr plan
bx cr quota
echo "If needed, discard older images using: bx cr image-rm"

echo "Current content of image registry"
bx cr images

echo "Checking registry namespace: ${REGISTRY_NAMESPACE}"
NS=$( bx cr namespaces | grep ${REGISTRY_NAMESPACE} ||: )
if [ -z ${NS} ]; then
    echo "Registry namespace ${REGISTRY_NAMESPACE} not found, creating it."
    bx cr namespace-add ${REGISTRY_NAMESPACE}
    echo "Registry namespace ${REGISTRY_NAMESPACE} created."
else 
    echo "Registry namespace ${REGISTRY_NAMESPACE} found."
fi