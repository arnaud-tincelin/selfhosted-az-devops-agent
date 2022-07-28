# Terraform implementation

This repository relies on Terraform to deploy:

- a resource group
- a VNET with 2 subnets to host the container apps
- a container registry to store the agent image + build & publish the docker image
- a log analytics workspace to store logs from the container apps
- a container apps environment + a container apps

## Deploy the solution

1. Create a variables file (such as `variables.auto.tfvars`) from the following template:

    ```hcl
    subscription_id     = "XXXXXXX"
    location            = "westeurope"
    azp_url             = "https://dev.azure.com/myOrg"
    azp_token           = "XXXXXXXXX"
    azp_pool            = "SelfHosted"
    azp_poolID          = "11"
    agents_min_replicas = 0
    agents_max_replicas = 3
    ```

1. Optional: to store the tfstate remotely, create a file with the remote backend configuration
1. Run the following commands:

    ```bash
    az login
    terraform init
    terraform apply -auto-approve
    ```
