variable "resource_group_name" {
    default     = "Storage"
    description  = "Resourcer Group Azure"
}

variable "location"  {
  default     = "eastus"
  description = "Location Azure"
}

variable "storage_account_name"{
    default = "storageteste0101"
    description = "Nome do storage account"
}

variable "nos_of_storage_accounts" {
  type=number
}