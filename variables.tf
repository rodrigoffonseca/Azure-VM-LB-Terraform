variable "scripturl" {
  type =  string
}

variable "adminname" {
  type = string
  default = "rfonseca"
}

variable "adminpwd" {
  type = string
  default = "P@ssword123456"
}

variable "location" {}

variable "workspace_to_environment_map" {
  type = map(string)
  default = {
    dev     = "dev"
    qa      = "qa"
    prod    = "prod"
  }
}

variable "environment_to_size_map" {
  type = map(string)
  default = {
    dev     = "Standard_B2s"
    qa      = "Standard_B2s"
    prod    = "Standard_D2s_v3"
  }
}
variable "prefix" {
    type = string
    default = "my"
}

variable "tags" {
    type = map(string)
    default = {
        Environment = "Terraform GS"
        Dept = "Engineering"
        dev     = "dev"
        qa      = "qa"
        prod    = "prod"
  }
}

variable "sku" {
    default = {
        westus = "16.04-LTS"
        eastus = "18.04-LTS"
    }
}

variable "workspace_to_size_map" {
  type = map(string)
  default = {
    dev = "Standard_B2s"
    qa      = "Standard_B2s"
    prod    = "Standard_D2s_v3"
  }
}