variable "cidr_blocks" {}

variable "aws_account_id" {}

variable "organization" {}

variable "region" {}

data "aws_availability_zones" "available" {}

locals {
  common_tags = "${list(
  map("Terraform", "true"),
  map("Organization", var.organization)
  )}"
}