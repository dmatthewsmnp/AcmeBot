variable "tags" {
  default = {
    Owner       = "Darryl Matthews"
    Environment = "Development"
    Automation  = "Terraform"
    WhatIsThis  = "Project for messing around with TF resources"
  }
}
variable "env" {
  type    = string
  default = "dev"
}
variable "allowed_ips" {
  type    = list(string)
  default = ["165.225.208.0/23", "165.225.210.0/23", "99.231.168.187"] # NOTE: ZScaler Toronto and Vancouver CIDRs, allow in dev only
}
