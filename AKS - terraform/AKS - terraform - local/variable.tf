variable "resource_group_name" {
    default     = "terraform-app"
    description  = "Resourcer Group Azure"
}

variable "location"  {
  default     = "eastus"
  description = "Location Azure"
}

variable "aks" {
  default = "clusteraks0101"
  description = "AKS Azure"
}