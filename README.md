# Complete example to deploy AzureDevops Agents on Container Apps

This example deploys a full environment to support azure devops agents. For each new pipeline, one agent container will be instanciated, and then removed once the pipeline ends.

Note: If there is no agent in the pool, the pipeline will fail. To workaround this limitation, a "placeholder" agent must be configured in order to always have 1 agent in the pool. This agent will be a "fake" agent as it will always be marked as offline.

## PAT required permissions

- `Agent Pools`: `Read & manage` to be able to register / unregister agents
- `Build`: `Read` for Keda to be able to get the queue of pending builds

## Deploy the solution

Using Terraform, this solution deploys:

- a resource group
- a VNET with 2 subnets to host the container apps
- a container registry to store the agent image + build & publish the docker image
- a log analytics workspace to store logs from the container apps
- a container apps environment + a container apps

To deploy, run the following commands:

```bash
az login
terraform init
terraform apply -auto-approve
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

- From an azure devops agent pool, click on "New Agent" and follow the instructions. You might need a temporary VM to install the agent. The VM might be deleted once the agent has been registered in the pool.

## References

- [Docker Agents for Azure Devops](https://docs.microsoft.com/en-us/azure/devops/pipelines/agents/docker?view=azure-devops#linux)
- [Keda for Azure Pipelines](https://keda.sh/docs/2.5/scalers/azure-pipelines/)
- [Keda](https://keda.sh/docs/2.6/deploy/#yaml)
- [Terraform](https://learn.hashicorp.com/tutorials/terraform/install-cli)
- [Container Apps](https://docs.microsoft.com/en-gb/azure/container-apps/containers)
