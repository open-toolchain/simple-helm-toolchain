#!/bin/bash
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
echo "Checking for Dockerfile at the repository root"
if [ -f Dockerfile ]; then 
   echo "Dockerfile found"
else
    echo "Dockerfile not found"
    exit 1
fi

echo "=========================================================="
echo "Checking registry current plan and quota"
bx cr plan
bx cr quota
echo "If needed, discard older images using: bx cr image-rm"

echo "Checking registry namespace: ${REGISTRY_NAMESPACE}"
NS=$( bx cr namespaces | grep ${REGISTRY_NAMESPACE} ||: )
if [ -z ${NS} ]; then
    echo "Registry namespace ${REGISTRY_NAMESPACE} not found, creating it."
    bx cr namespace-add ${REGISTRY_NAMESPACE}
    echo "Registry namespace ${REGISTRY_NAMESPACE} created."
else 
    echo "Registry namespace ${REGISTRY_NAMESPACE} found."
fi

echo -e "Existing images in registry"
bx cr images

echo "=========================================================="
echo -e "Building container image: ${IMAGE_NAME}:${BUILD_NUMBER}"
set -x
bx cr build -t ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}:${BUILD_NUMBER} .
set +x
bx cr image-inspect ${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}:${BUILD_NUMBER}

# When 'bx' commands are in the pipeline job config directly, the image URL will automatically be passed 
# along with the build result as env variable PIPELINE_IMAGE_URL to any subsequent job consuming this build result. 
# When the job is sourc'ing an external shell script, or to pass a different image URL than the one inferred by the pipeline,
# please uncomment and modify the environment variable the following line.
export PIPELINE_IMAGE_URL="$REGISTRY_URL/$REGISTRY_NAMESPACE/$IMAGE_NAME:$BUILD_NUMBER"
echo "TODO - remove once no longer needed to unlock VA job ^^^^"

# Provision a registry token for this toolchain to later pull image. Token will be passed into build.properties
echo "=========================================================="
TOKEN_DESCR="bluemix-toolchain-${PIPELINE_TOOLCHAIN_ID}"
echo "Checking registry token for toolchain: ${TOKEN_DESCR}"
EXISTING_TOKEN=$(bx cr tokens | grep ${TOKEN_DESCR} ||: )
if [ -z ${EXISTING_TOKEN} ]; then
    echo -e "Creating new registry token: ${TOKEN_DESCR}"
    bx cr token-add --non-expiring --description ${TOKEN_DESCR}
    REGISTRY_TOKEN_ID=$(bx cr tokens | grep ${TOKEN_DESCR} | awk '{ print $1 }')
else    
    echo -e "Reusing existing registry token: ${TOKEN_DESCR}"
    REGISTRY_TOKEN_ID=$(echo $EXISTING_TOKEN | awk '{ print $1 }')
fi
REGISTRY_TOKEN=$(bx cr token-get ${REGISTRY_TOKEN_ID} --quiet)
echo -e "REGISTRY_TOKEN=${REGISTRY_TOKEN}"

echo "=========================================================="
echo "Copying artifacts needed for deployment and testing"

echo "Checking archive dir presence"
mkdir -p $ARCHIVE_DIR

# CHART information from build.properties is used in Helm Chart deployment to set the release name
echo "CHART_NAME=${CHART_NAME}" >> $ARCHIVE_DIR/build.properties
# IMAGE information from build.properties is used in Helm Chart deployment to set the release name
echo "IMAGE_NAME=${IMAGE_NAME}" >> $ARCHIVE_DIR/build.properties
echo "BUILD_NUMBER=${BUILD_NUMBER}" >> $ARCHIVE_DIR/build.properties
# REGISTRY information from build.properties is used in Helm Chart deployment to generate cluster secret
echo "REGISTRY_URL=${REGISTRY_URL}" >> $ARCHIVE_DIR/build.properties
echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}" >> $ARCHIVE_DIR/build.properties
echo "REGISTRY_TOKEN=${REGISTRY_TOKEN}" >> $ARCHIVE_DIR/build.properties
cat $ARCHIVE_DIR/build.properties

echo "Copy pipeline scripts along with the build"
# Copy scripts (incl. deploy scripts)
if [ -d ./scripts/ ]; then
  if [ ! -d $ARCHIVE_DIR/scripts/ ]; then # no need to copy if working in ./ already
    cp -r ./scripts/ $ARCHIVE_DIR/
  fi
fi

echo "Copy Helm chart along with the build"
if [ -d ./chart//${CHART_NAME} ]; then
  if [ ! -d $ARCHIVE_DIR/chart/ ]; then # no need to copy if working in ./ already
    cp -r ./chart/ $ARCHIVE_DIR/
  fi
else 
    echo -e "${red}Helm chart for Kubernetes deployment (/chart/${CHART_NAME}) not found.${no_color}"
    exit 1
fi