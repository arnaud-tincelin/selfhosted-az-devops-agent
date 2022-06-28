#!/bin/bash

set -e

RG_NAME=$1
LOCATION=$2
ACR_NAME=$3
WORKSPACE_NAME=$4
AZP_URL=$5
AZP_POOL=$6
AZP_POOLID=$7
AZP_TOKEN=$8
MAX_REPLICAS=$9

az login -o none

image="devops/agent:1.0"

acr=`az deployment group create --resource-group ${RG_NAME} --template-file ./acr.json --parameters name=${ACR_NAME} location=${LOCATION}`
loginServer=`jq -r '.properties.outputs.loginServer.value' <<<${acr}`
username=`jq -r '.properties.outputs.username.value' <<<${acr}`
password=`jq -r '.properties.outputs.password.value' <<<${acr}`

az acr login --name ${loginServer} -u ${username} -p ${password}
az acr build --registry ${loginServer} -t ${image} ../docker

az deployment group create --resource-group ${RG_NAME} --template-file ./aca.json \
  --parameters location=${LOCATION} \
    workspaceName=${WORKSPACE_NAME} \
    azp_url=${AZP_URL} \
    azp_token=${AZP_TOKEN} \
    azp_pool=${AZP_POOL} \
    azp_poolID=${AZP_POOLID} \
    registry_server=${loginServer} \
    registry_username=${username} \
    registry_password=${password} \
    image=${loginServer}/${image} \
    min_replicas=0 \
    max_replicas=${MAX_REPLICAS}
