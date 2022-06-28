variable "subscription_id" {
  type = string
  description = "Target subscription where resources will be deployed"
}

variable "location" {
  type = string
  description = "Note: the value must follow the ARM template format. Ex: 'westeurope' instead of 'west europe'"
}

variable "azp_url" {
  type        = string
  description = "URL to the azure devops organization."
}

variable "azp_token" {
  type        = string
  description = "Azure Devops Personnal Access Token."
}

variable "azp_pool" {
  type        = string
  description = "Name of the azure devops pool that agents shall join."
}

# Note: in Keda v2.6, poolName can be used instead of poolID (https://keda.sh/docs/2.6/scalers/azure-pipelines/)
variable "azp_poolID" {
  type        = string
  description = "ID of the azure devops pool that agents shall join."
}

variable "agents_min_replicas" {
  type    = number
  default = 0
}

variable "agents_max_replicas" {
  type        = number
  description = "Maximum number of agents to instantiate. This should match the maximum number of self hosted agents configured in azure devops."
}
