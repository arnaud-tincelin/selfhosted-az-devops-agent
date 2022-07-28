#! /bin/bash

# usage:
# ./deploy.sh subscriptionID https://dev.azure.com/xxx poolName PAT

set -e

SUBSCRIPTION=$1
DEVOPS_URL=$2
POOL_NAME=$3
PAT=$4

RG_NAME=az-devops-runner-aks
KUBE_CONFIG=./kubeconfig
IMAGE=az-devops/runner:1.0

az login -o none

echo "[INF] Register AKS extensions"
az extension add --upgrade --name aks-preview -o none
az feature register --subscription ${SUBSCRIPTION} --name AKS-KedaPreview --namespace Microsoft.ContainerService -o none

echo "[INF] Create RG"
az group create --subscription ${SUBSCRIPTION} --name ${RG_NAME} --location westeurope -o none

echo "[INF] Create ACR"
REGISTRY_HOST=`az acr create --subscription ${SUBSCRIPTION} --resource-group ${RG_NAME} --name azdevopsrunner --sku Basic -o tsv --query 'loginServer'`

echo "[INF] Build & Push docker image to ACR"
# https://docs.microsoft.com/en-us/cli/azure/acr?view=azure-cli-latest#az-acr-build
az acr build --registry ${REGISTRY_HOST} --image ${IMAGE} --no-wait ../docker/

echo "[INF] Create AKS with Keda"
# https://docs.microsoft.com/en-us/azure/aks/keda-deploy-add-on-cli
az aks create \
  --subscription ${SUBSCRIPTION} \
  --resource-group ${RG_NAME} \
  --name az-devops-runner \
  --enable-keda \
  --generate-ssh-keys \
  --attach-acr azdevopsrunner \
  -o none

echo "[INF] Get Kubeconfig"
az aks get-credentials \
  --admin \
  --subscription ${SUBSCRIPTION} \
  --resource-group ${RG_NAME} \
  --name az-devops-runner \
  --file ${KUBE_CONFIG} \
  --overwrite-existing

# Note: the secret is as plain text in env variable. See https://keda.sh/docs/2.7/scalers/azure-pipelines/ for using a secret
# https://keda.sh/blog/2021-05-27-azure-pipelines-scaler/
cat << EOF > ./manifest.yaml
apiVersion: keda.sh/v1alpha1
kind: ScaledJob
metadata:
  name: azdevops-scaledjob
spec:
  jobTargetRef:
    template:
      spec:
        containers:
        - name: azdevops-agent-job
          image: ${REGISTRY_HOST}/${IMAGE}
          imagePullPolicy: Always
          env:
          - name: AZP_URL
            value: ${DEVOPS_URL}
          - name: AZP_TOKEN
            value: ${PAT}
          - name: AZP_POOL
            value: ${POOL_NAME}
  maxReplicaCount: 3           
  triggers:
  - type: azure-pipelines
    metadata:
      poolName: ${POOL_NAME}
      organizationURLFromEnv: "AZP_URL"
      personalAccessTokenFromEnv: "AZP_TOKEN"
EOF

echo "[INF] Apply manifest"
kubectl apply -f manifest.yaml

echo "[INF] It is now possible to leverage Az DevOps private runner from Agent Pool ${POOL_NAME}"
echo "[INF] Debugging: KUBECONFIG=./kubeconfig kubectl describe ScaledJob azdevops-scaledjob"
