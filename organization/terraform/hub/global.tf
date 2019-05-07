variable "cidr_blocks" {}

variable "tier" {}

variable "aws_account_id" {}

variable "organization" {}

data "aws_availability_zones" "available" {}

locals {
  common_tags = "${list(
  map("Terraform", "true"),
  map("Organization", var.organization)
  )}"
}