variable "cidr_blocks" {}

variable "aws_account_id" {}

variable "organization" {}

variable "region" {}

data "aws_availability_zones" "available" {}

locals {
  common_tags = {
    Terraform    = "true"
    Organization = "${var.organization}"
  }
}
