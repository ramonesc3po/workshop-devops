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
  type = "map"
}

resource "aws_security_group" "jenkins" {
  vpc_id = "${aws_vpc.hub.id}"

}

resource "aws_instance" "jenkins" {
  ami = "${data.aws_ami.jenkins.id}"
  instance_type = "${var.ec2_jenkins_type[var.tier]}"
}