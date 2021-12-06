variable "resource_group_name" {
    default     = "azurefunction"
    description  = "Resourcer Group Azure"
}

variable "location"  {
  default     = "eastus"
  description = "Location Azure"
}

variable "serviceplan_name" {
  default     = "terraform-sp-prod"
  description = "Service plan Azure"
}
