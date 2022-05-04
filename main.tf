resource "azurerm_resource_group" "this" {
  name     = "devops-agents"
  location = var.location
}

resource "azurerm_virtual_network" "this" {
  name                = "devops-agents"
  location            = var.location
  resource_group_name = azurerm_resource_group.this.name
  address_space       = ["10.0.0.0/16"]
}

resource "azurerm_subnet" "infrastructure" {
  name                 = "infrastructure"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.0.0/21"]
}

resource "azurerm_subnet" "runtime" {
  name                 = "runtime"
  resource_group_name  = azurerm_resource_group.this.name
  virtual_network_name = azurerm_virtual_network.this.name
  address_prefixes     = ["10.0.8.0/21"]
}

resource "azurerm_log_analytics_workspace" "this" {
  name                = "atiDevopsAgents"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_container_registry" "this" {
  name                = "atiDevopsAgents"
  resource_group_name = azurerm_resource_group.this.name
  location            = var.location
  sku                 = "Standard"
  admin_enabled       = true
}

locals {
  image_name = "devops/agent:1.0"
}

resource "null_resource" "build_image" {
  triggers = {
    dockerfile         = filemd5("${path.module}/docker/Dockerfile") # this variable aims to trigger image rebuild on file changes
    startfile          = filemd5("${path.module}/docker/start.sh") # this variable aims to trigger image rebuild on file changes
    acr_name           = azurerm_container_registry.this.name
    acr_rg             = azurerm_container_registry.this.resource_group_name
    image_name         = local.image_name
  }

  provisioner "local-exec" {
    command = <<EOT
    az acr login --name ${self.triggers.acr_name}
    az acr build --registry ${self.triggers.acr_name} -t ${self.triggers.image_name} ${path.module}/docker
    EOT
  }
}

# https://docs.microsoft.com/en-us/azure/templates/microsoft.app/managedenvironments?tabs=json
resource "azurerm_resource_group_template_deployment" "container_apps" {
  name                = "container-apps"
  resource_group_name = azurerm_resource_group.this.name
  deployment_mode     = "Incremental"
  parameters_content = jsonencode({
    "location" = {
      value = var.location
    }
    "azp_url" = {
      value = var.azp_url
    }
    "azp_token" = {
      value = var.azp_token
    }
    "azp_pool" = {
      value = var.azp_pool
    }
    "azp_poolID" = {
      value = var.azp_poolID
    }
    "registry_server" = {
      value = azurerm_container_registry.this.login_server
    }
    "registry_username" = {
      value = azurerm_container_registry.this.admin_username
    }
    "registry_password" = {
      value = azurerm_container_registry.this.admin_password
    }
    "image" = {
      value = "${azurerm_container_registry.this.login_server}/${local.image_name}"
    }
    "min_replicas" = {
      value = var.agents_min_replicas
    }
    "max_replicas" = {
      value = var.agents_max_replicas
    }
    "log_analytics_customer_id" = {
      value = azurerm_log_analytics_workspace.this.workspace_id
    }
    "log_analytics_shared_key" = {
      value = azurerm_log_analytics_workspace.this.primary_shared_key
    }
    "infrastructureSubnetId" = {
      value = azurerm_subnet.infrastructure.id
    }
    "runtimeSubnetId" = {
      value = azurerm_subnet.runtime.id
    }
  })
  template_content = file("${path.module}/container_apps.json")
  depends_on = [
    null_resource.build_image, // required to avoid error "MANIFEST_UNKNOWN: manifest tagged by \\\"XXXX\\\" is not found"
  ]
}
