# Complete example to deploy AzureDevops Agents on Container Apps

This example deploys a full environment to support azure devops agents. For each new pipeline, one agent container will be instanciated, and then removed once the pipeline ends.

Note: If there is no agent in the pool, the pipeline will fail. To workaround this limitation, a "placeholder" agent must be configured in order to always have 1 agent in the pool. This agent will be a "fake" agent as it will always be marked as offline.

## Pre-requisites

1. Create an agent pool and save its **name** and **id**.  
    Note: the pool ID corresponds to the `queueId` from the url when a pool is selected in the browser.  
    Example: `https://dev.azure.com/myOrg/myProject/_settings/agentqueues?queueId=11&view=jobs`, the pool ID is 11
1. Create a **PAT** (Personal Access Token) with the following permissions:
    - `Agent Pools`: `Read & manage` to be able to register / unregister agents
    - `Build`: `Read` for Keda to be able to get the queue of pending builds
1. Configure the **max number of parallel jobs** in Azure Devops so that your ACA does scale accordingly

## Deploy the solution

This repository deploys:

- a resource group
- a VNET with 2 subnets to host the container apps
- a container registry to store the agent image + build & publish the docker image
- a log analytics workspace to store logs from the container apps
- a container apps environment + a container apps

There are 2 implementations of the same infrastructure in this repository:

- using Terraform in the `terraform` folder:  
    To deploy, run the following commands:

    ```bash
    az login
    terraform init
    terraform apply -auto-approve
    ```

- using ARM template in the `arm` folder:
    To deploy, run the following commands:

    ```bash
    ./deploy.sh myRG myLocation myACR myWorkspace https://dev.azure.com/myOrg myPoolName myPoolID myToken MaxRunnerCount
    ```

## Create a "placeholder" agent

There are 2 possibilities to deploy a placeholder agent:

- using the provided terraform code, the following commands will, create a VM, register it as a devops agent and finally remove it (leaving the agent in the azure devops pool):

    ```bash
    cd placeholder-agent
    az login
    terraform init
    terraform apply -auto-approve
    # Wait for the agent to appear in the pool before running destroy
    terraform destroy -auto-approve
    cd -
    ```

- From an azure devops agent pool, click on "New Agent" and follow the instructions. You will need a temporary VM to install the agent. The VM might be deleted once the agent has been registered in the pool.

## References

- [Container Apps ARM Template](https://docs.microsoft.com/en-us/azure/templates/microsoft.app/containerapps?tabs=json)
- [Docker Agents for Azure Devops](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux)
- [Keda for Azure Pipelines](https://keda.sh/docs/2.5/scalers/azure-pipelines/)
- [Keda](https://keda.sh/docs/2.6/deploy/#yaml)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Container Apps](https://docs.microsoft.com/en-gb/azure/container-apps/containers)
