#!/bin/bash

# Input parameters configured via Env Variables (e.g. build.properties)
# CHART_NAME
# IMAGE_NAME
# BUILD_NUMBER
# REGISTRY_URL
# REGISTRY_NAMESPACE
# REGISTRY_TOKEN

# Input parameters configured by Pipeline job automatically
# PIPELINE_KUBERNETES_CLUSTER_NAME
# CLUSTER_NAMESPACE
# REGISTRY_URL

#set -x

#View build properties
cat build.properties

echo "=========================================================="
echo "Prefix release name with namespace if not 'default' as Helm needs unique release names across namespaces"
echo "(see also https://github.com/kubernetes/helm/issues/3037)"
if [[ "${CLUSTER_NAMESPACE}" != "default" ]]; then
  RELEASE_NAME="${CLUSTER_NAMESPACE}-${IMAGE_NAME}"
else
  RELEASE_NAME=${IMAGE_NAME}
fi
echo -e "Release name: ${RELEASE_NAME}"

echo "Checking Helm Chart"
helm lint ${RELEASE_NAME} ./chart/${CHART_NAME}

echo "=========================================================="
echo "Deploying Helm Chart"

IMAGE_REPOSITORY=${REGISTRY_URL}/${REGISTRY_NAMESPACE}/${IMAGE_NAME}

echo -e "Dry run into: ${PIPELINE_KUBERNETES_CLUSTER_NAME}/${CLUSTER_NAMESPACE}."
helm upgrade ${RELEASE_NAME} ./chart/${CHART_NAME} --set image.repository=${IMAGE_REPOSITORY},image.tag=${BUILD_NUMBER} --namespace ${CLUSTER_NAMESPACE} --install --debug --dry-run

echo -e "Deploying into: ${PIPELINE_KUBERNETES_CLUSTER_NAME}/${CLUSTER_NAMESPACE}."
helm upgrade ${RELEASE_NAME} ./chart/${CHART_NAME} --set image.repository=${IMAGE_REPOSITORY},image.tag=${BUILD_NUMBER} --namespace ${CLUSTER_NAMESPACE} --install

echo ""
echo "Deployed Services:"
kubectl describe services ${RELEASE_NAME}-${CHART_NAME} --namespace ${CLUSTER_NAMESPACE}

echo ""
echo "Deployed Pods:"
kubectl describe pods --selector app=${CHART_NAME} --namespace ${CLUSTER_NAMESPACE}

echo ""
echo "=========================================================="
#Check cluster availability
echo "=========================================================="
IP_ADDR=$(bx cs workers ${PIPELINE_KUBERNETES_CLUSTER_NAME} | grep normal | awk '{ print $2 }')
PORT=$(kubectl get services --namespace ${CLUSTER_NAMESPACE} | grep ${PREFIXED_RELEASE_NAME}-${CHART_NAME} | sed 's/.*:\([0-9]*\).*/\1/g')
echo -e "View the application at: http://${IP_ADDR}:${PORT}"