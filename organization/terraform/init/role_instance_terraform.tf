resource "aws_iam_role" "ec2_instance_jenkins" {
  name        = "role-instance-jenkins"
  description = "Permitir que serviços do Jenkins utilize recursos da aws"

  assume_role_policy = "${data.aws_iam_policy_document.role_ec2_instance_jenkins.json}"
}

resource "aws_iam_instance_profile" "ec2_instance_jenkins" {
  name = "role-instance-jenkins"
  role = "${aws_iam_role.ec2_instance_jenkins.id}"
}

resource "aws_iam_role_policy" "allow_full" {
  name   = "allow-full"
  role   = "${aws_iam_role.ec2_instance_jenkins.id}"
  policy = "${data.aws_iam_policy_document.allow_full.json}"
}

data "aws_iam_policy_document" "allow_full" {
  statement {
    sid    = "AllowFull"
    effect = "Allow"

    actions = ["*"]

    resources = ["*"]
  }
}

data "aws_iam_policy_document" "role_ec2_instance_jenkins" {
  statement {
    sid    = "AssumeRole"
    effect = "Allow"

    actions = [
      "sts:AssumeRole",
    ]

    principals {
      type = "Service"

      identifiers = [
        "ec2.amazonaws.com",
      ]
    }
  }
}

output "role_instance_jenkins_arn" {
  value = "${aws_iam_role.ec2_instance_jenkins.arn}"
}
