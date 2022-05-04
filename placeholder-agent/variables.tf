variable "subscription_id" {
  type        = string
  description = "Target subscription where resources will be deployed"
}

variable "location" {
  type        = string
  description = "Note: the value must follow the ARM template format. Ex: 'westeurope' instead of 'west europe'"
}

variable "resource_group_name" {
  type = string
}

variable "subnet_id" {
  type=string
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
