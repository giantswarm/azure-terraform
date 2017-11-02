### Main ###

variable "cluster_name" {
  type        = "string"
  description = "Need to be unique within the account"
}

variable "azure_location" {
  type        = "string"
  description = "An Azure location where the cluster will be built."
}

variable "azure_cloud" {
  description = "Azure cloud to use. Possible values can be found here: https://github.com/Azure/go-autorest/blob/ec5f4903f77ed9927ac95b19ab8e44ada64c1356/autorest/azure/environments.go#L13"
  default     = "AZUREPUBLICCLOUD"
}

variable "g8s_vault_token" {
  type        = "string"
  description = "Vault token used by nodes for bootstrapping. Should be defined after Vault is installed."
}

### Compute and Storage ###

variable "bastion_vm_size" {
  type    = "string"
  default = "Standard_A1"
}

variable "bastion_storage_type" {
  type    = "string"
  default = "Standard_LRS"
}

variable "vault_vm_size" {
  type    = "string"
  default = "Standard_DS1_v2"
}

variable "vault_storage_type" {
  type    = "string"
  default = "Premium_LRS"
}

### Container Linux ###

variable "container_linux_channel" {
  description = "Cotainer linux channel (e.g. stable, beta, alpha)."
  default     = "stable"
}

variable "container_linux_version" {
  description = "Container linux version."
  default     = "latest"
}

### DNS ###

variable "base_domain" {
  type        = "string"
  description = "Base domain for g8s cluster (i.e. $cluster_name.$azure_location.azure.gigantic.io)."
}

variable "vault_dns" {
  type        = "string"
  description = "vault DNS prefix (i.e. vault)."
  default     = "vault"
}

variable "api_dns" {
  type        = "string"
  description = "FQDN for api (i.e. g8s)."
  default     = "g8s"
}

variable "etcd_dns" {
  type        = "string"
  description = "FQDN for etcd (i.e. etcd)."
  default     = "etcd"
}

variable "ingress_dns" {
  type        = "string"
  description = "FQDN for ingress (i.e. ingress)."
  default     = "ingress"
}

variable "root_dns_zone_name" {
  description = "Root DNS zone name (i.e. azure.gigantic.io)"
  default     = ""
}

variable "root_dns_zone_rg" {
  description = "Root DNS zone resource group"
  default     = "root_dns_zone_rg"
}

### Network ###

variable "vnet_cidr" {
  description = "CIDR for VMs internal virtual network."
  default     = "10.0.0.0/16"
}

variable "calico_cidr" {
  description = "CIDR for Calico."
  default     = "192.168.0.0/16"
}

variable "docker_cidr" {
  description = "CIDR for Docker."
  default     = "172.17.0.1/16"
}

variable "k8s_service_cidr" {
  description = "CIDR for k8s internal cluster network."
  default     = "172.31.0.0/24"
}

variable "k8s_dns_ip" {
  description = "IP for k8s internal DNS server."
  default     = "172.31.0.10"
}

variable "k8s_api_ip" {
  description = "IP for k8s internal API server."
  default     = "172.31.0.1"
}

variable "subnet_bastion_0" {
  description = "CIDR for bastion network 0."
  default     = "10.0.1.0/25"
}

variable "subnet_bastion_1" {
  description = "CIDR for bastion network 1."
  default     = "10.0.1.128/25"
}

variable "subnet_lb_0" {
  description = "CIDR for load balancer network 0."
  default     = "10.0.2.0/25"
}

variable "subnet_lb_1" {
  description = "CIDR for load balancer network 1."
  default     = "10.0.2.128/25"
}

variable "subnet_vault_0" {
  description = "CIDR for Vault network."
  default     = "10.0.3.0/25"
}

variable "subnet_worker_0" {
  description = "CIDR for worker network 0."
  default     = "10.0.5.0/25"
}

variable "subnet_worker_1" {
  description = "CIDR for worker network 1."
  default     = "10.0.5.128/25"
}
