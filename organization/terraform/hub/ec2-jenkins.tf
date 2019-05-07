data "aws_ami" "jenkins" {
  most_recent = "true"

  owners = ["${var.aws_account_id}"]

  filter {
    name   = "name"
    values = ["jenkins*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  filter {
    name   = "tag:OS_Version"
    values = ["Ubuntu*"]
  }
}

variable "ec2_jenkins_type" {
  type = "string"
}

resource "aws_security_group" "jenkins" {
  name        = "jenkins"
  description = "Security group jenkins"
  vpc_id      = "${aws_vpc.hub.id}"

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"

    cidr_blocks = [
      "0.0.0.0/0",
    ]
  }

  tags = "${merge(merge(local.common_tags, map("Name", "jenkins")))}"
}

##
# Generate ssh key
##
data "tls_public_key" "ec2_jenkins" {
  private_key_pem = "${tls_private_key.ec2_jenkins.private_key_pem}"
}

resource "tls_private_key" "ec2_jenkins" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "ec2_jenkins" {
  key_name_prefix = "jenkins"
  public_key      = "${data.tls_public_key.ec2_jenkins.public_key_openssh}"
}

data "aws_iam_role" "ec2_jenkins" {
  name = "role-instance-jenkins"
}

##
# Create Jenkins instance
##
resource "aws_instance" "ec2_jenkins" {
  count         = 1
  ami           = "${data.aws_ami.jenkins.id}"
  instance_type = "${var.ec2_jenkins_type}"
  key_name      = "${aws_key_pair.ec2_jenkins.key_name}"

  iam_instance_profile = "${data.aws_iam_role.ec2_jenkins.id}"

  user_data = <<-EOF
  #!/bin/bash
  apt-get update
  apt-get install ansible awscli -y
  EOF

  subnet_id = "${element(aws_subnet.public_subnet.*.id, 0)}"

  vpc_security_group_ids = ["${aws_security_group.jenkins.id}"]

  root_block_device {
    volume_size           = "8"
    volume_type           = "gp2"
    delete_on_termination = true
  }

  volume_tags = "${merge(merge(local.common_tags, map("Name", "jenkins")))}"
  tags        = "${merge(merge(local.common_tags, map("Name", "jenkins")))}"

  depends_on = [
    "aws_ebs_volume.jenkins_files",
  ]
}

resource "aws_volume_attachment" "attach_jenkins_files" {
  device_name = "/dev/sdf"
  instance_id = "${aws_instance.ec2_jenkins.id}"
  volume_id   = "${aws_ebs_volume.jenkins_files.id}"

  depends_on = [
    "aws_instance.ec2_jenkins",
    "aws_ebs_volume.jenkins_files",
  ]
}

resource "aws_ebs_volume" "jenkins_files" {
  availability_zone = "${element(aws_subnet.private_subnet.*.availability_zone, 0)}"
  size              = 15
  type              = "gp2"

  tags = "${merge(merge(local.common_tags, map("Name", "jenkins-files")))}"
}

resource "random_string" "execute_if_change" {
  length = 10

  keepers = {
    execute_if_change = "${aws_instance.ec2_jenkins.id}"
  }

  provisioner "remote-exec" {
    connection {
      host        = "${aws_instance.ec2_jenkins.public_ip}"
      private_key = "${tls_private_key.ec2_jenkins.private_key_pem}"
      user        = "ubuntu"
    }

    script = "scripts/format_jenkinsfiles.sh"
  }

  depends_on = [
    "aws_volume_attachment.attach_jenkins_files",
    "aws_instance.ec2_jenkins",
  ]
}

output "jenkins_ssh_key" {
  value = "${tls_private_key.ec2_jenkins.private_key_pem}"
}

output "jenkins_public_ip" {
  value = "${aws_instance.ec2_jenkins.public_ip}"
}
