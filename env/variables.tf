variable "project" {
  type = string
}

variable "environment" {
  type    = string
  default = "dev"
}

variable "location" {
  type    = string
  default = "westeurope"
}

variable "address_space" {
  type    = list(string)
  default = ["10.20.0.0/16"]
}

variable "subnet_prefixes" {
  type    = list(string)
  default = ["10.20.1.0/24"]
}

variable "tags" {
  type    = map(string)
  default = {}
}
