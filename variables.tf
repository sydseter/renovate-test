
variable "renovate_container_image" {
  type = string
  description = "Fully qualified image name and tag for the renovate container image"
}

variable "subscription_id" {
  type = string
  description = "azure subscription id"
}

variable "renovate_autodiscover" {
  type = string
}

variable "renovate_github_token" {
  type = string
  sensitive = true
}

variable "renovate_private_key" {
  type = string
  sensitive = true
}

variable "npm_registry_npmjs_org_token" {
  type = string
  sensitive = true
}

variable "container_registry_url" {
  type = string
  default = "https://ghcr.io"
  description = "URL to container registry."
}

variable "container_registry_username" {
  type = string
  description = "Username to authenticate against the container registry."
}

variable "container_registry_password" {
  type = string
  sensitive = true
  description = "Password to authenticate against the container registry."
}

variable "kubernetes_config_path" {
  type = string
  default = "~/.kube/config"
  description = "config path"
}
