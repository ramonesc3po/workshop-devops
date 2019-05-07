provider "aws" {
  assume_role {
    role_arn     = "arn:aws:iam::082715569515:role/role-instance-jenkins"
    session_name = "terraform"
  }

  region = "${var.region}"
}

terraform {
  backend "s3" {
    key            = "hub/terraform.tfstate"
    kms_key_id     = "arn:aws:kms:us-east-1:082715569515:key/261500aa-90e4-4769-bb62-abd5291d4859"
    bucket         = "terraform-aws-us-east-1-backend"
    region         = "us-east-1"
    encrypt        = "true"
  }
}
