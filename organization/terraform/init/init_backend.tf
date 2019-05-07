provider "aws" {
  region = "us-east-1"
}

locals {
  name_backend = "terraform-aws-us-east-1-backend"
}

resource "aws_kms_key" "backend_terraform" {
  description             = "Chave de encriptaçao do ${local.name_backend}"
  deletion_window_in_days = 7

  tags {
    Name         = "${local.name_backend}"
    Terraform    = true
    Organization = "lab4ever"
  }
}

resource "aws_s3_bucket" "backend_terraform" {
  region = "us-east-1"
  bucket = "${local.name_backend}"
  acl    = "private"

  server_side_encryption_configuration {
    "rule" {
      "apply_server_side_encryption_by_default" {
        sse_algorithm     = "aws:kms"
        kms_master_key_id = "${aws_kms_key.backend_terraform.arn}"
      }
    }
  }

  versioning {
    enabled = true
  }

  tags {
    Name          = "${local.name_backend}"
    Terraform     = true
    Organizaztion = "lab4ever"
  }

  depends_on = [
    "aws_kms_key.backend_terraform",
  ]
}

output "kms_key_id" {
  value = "${aws_kms_key.backend_terraform.key_id}"
}

output "kms_key_arn" {
  value = "${aws_kms_key.backend_terraform.arn}"
}

output "s3_backend_terraform_id" {
  value = "${aws_s3_bucket.backend_terraform.id}"
}

output "s3_backend_terraform_arn" {
  value = "${aws_s3_bucket.backend_terraform.arn}"
}
