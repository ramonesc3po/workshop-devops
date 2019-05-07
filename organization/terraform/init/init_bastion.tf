##
# Generate ssh key
##
data "tls_public_key" "init_bastion" {
  private_key_pem = "${tls_private_key.init_bastion.private_key_pem}"
}

resource "tls_private_key" "init_bastion" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "init_bastion" {
  key_name_prefix = "init-bastion"
  public_key      = "${data.tls_public_key.init_bastion.public_key_openssh}"

  provisioner "local-exec" {
    command = "echo ${tls_private_key.init_bastion.private_key_pem} > /tmp/init-bastion.pem"
  }
}

resource "aws_security_group" "init_bastion" {
  name        = "init_bastion"
  description = "Security group init_bastion"

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

  tags {
    Name = "init-bastion"
  }
}

##
# Create init-bastion instance
##
resource "aws_instance" "init_bastion" {
  count         = 1
  ami           = "ami-0a313d6098716f372"
  instance_type = "t2.micro"
  key_name      = "${aws_key_pair.init_bastion.key_name}"

  vpc_security_group_ids = ["${aws_security_group.init_bastion.id}"]

  iam_instance_profile = "${aws_iam_role.ec2_instance_jenkins.id}"

  user_data = <<-EOF
  #!/bin/bash
  apt-get update
  apt-get install ansible awscli unzip git -y ; apt-get clean
  curl -sS https://releases.hashicorp.com/terraform/0.11.13/terraform_0.11.13_linux_amd64.zip -o /tmp/terraform.zip && \
  cd /tmp ; unzip -q terraform.zip && \
  mv terraform /usr/local/bin
  EOF

  root_block_device {
    volume_size           = "8"
    volume_type           = "gp2"
    delete_on_termination = true
  }

  tags {
    Name         = "init-bastion"
    Organization = "lab4ever"
  }
/*
  provisioner "remote-exec" {
    connection {
      host = "${aws_instance.init_bastion.public_ip}"
      user = "ubuntu"
      private_key = "${tls_private_key.init_bastion.private_key_pem}"
    }

    inline = [
      "git clone https://github.com/ramonesc3po/workshop-devops.git",
      "cd workshop-devops/organization/terraform",
      "terraform init hub/",
      "terraform plan -var-file=conf/us-east-1-hub.tfvars -var-file=conf/global.tfvars -out=.terraform-hub.plan hub/",
    ]
  }
*/
  provisioner "local-exec" {
    command = "echo ${tls_private_key.init_bastion.private_key_pem} > /tmp/init-bastion.pem"
  }
}

output "init_bastion_public_ip" {
  value = "${aws_instance.init_bastion.public_ip}"
}

output "init_bastion_ssh_key" {
  value = "${tls_private_key.init_bastion.private_key_pem}"
}
