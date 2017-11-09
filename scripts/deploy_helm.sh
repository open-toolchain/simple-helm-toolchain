#!/bin/bash
# uncomment to debug the script
#set -x

echo "Input env variables (can be received via properties.file:"
echo "CHART_NAME=${CHART_NAME}"
echo "IMAGE_NAME=${IMAGE_NAME}"
echo "BUILD_NUMBER=${BUILD_NUMBER}"
echo "REGISTRY_URL=${REGISTRY_URL}"
echo "REGISTRY_NAMESPACE=${REGISTRY_NAMESPACE}"
echo "REGISTRY_TOKEN=${REGISTRY_TOKEN}"
#View build properties
# cat build.properties

# Input parameters configured by Pipeline job automatically
# PIPELINE_KUBERNETES_CLUSTER_NAME
# CLUSTER_NAMESPACE


echo "=========================================================="
echo "Prefix release name with namespace if not 'default' as Helm needs unique release names across namespaces"
echo "(see also https://github.com/kubernetes/helm/issues/3037)"
if [[ "${CLUSTER_NAMESPACE}" != "default" ]]; then
  RELEASE_NAME="${CLUSTER_NAMESPACE}-${IMAGE_NAME}"
else
  RELEASE_NAME=${IMAGE_NAME}
fi
echo -e "Release name: ${RELEASE_NAME}"

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