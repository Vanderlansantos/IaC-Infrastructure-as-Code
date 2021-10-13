variable "resource_group_name" {
    default     = "terraform-app"
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

variable "appservice_name" {
  default     = "terraform-app-serive"
  description = "App Service plan Azure"
}