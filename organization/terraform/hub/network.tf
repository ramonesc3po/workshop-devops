resource "aws_vpc" "hub" {
  cidr_block           = "${var.cidr_blocks}"
  enable_dns_hostnames = true
  enable_dns_support   = true

  instance_tenancy = "default"

  assign_generated_ipv6_cidr_block = false

  tags = "${concat(local.common_tags, list(
  map("key", "Name", "value", "hub")
  ))}"
}

resource "aws_subnet" "public_subnet" {
  count             = "${length(data.aws_availability_zones.available.names)}"
  vpc_id            = "${aws_vpc.hub.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.hub.cidr_block,6,0+count.index)}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"

  map_public_ip_on_launch = "true"

  lifecycle {
    create_before_destroy = true
  }

  tags = "${concat(local.common_tags, list(
  map("key","Name","value","public-${element(data.aws_availability_zones.available.names, count.index)}")
  ))}"
}

resource "aws_subnet" "private_subnet" {
  count             = "${length(data.aws_availability_zones.available.names)}"
  vpc_id            = "${aws_vpc.hub.id}"
  cidr_block        = "${cidrsubnet(aws_vpc.hub.cidr_block,6,7+count.index)}"
  availability_zone = "${element(data.aws_availability_zones.available.names, count.index)}"

  map_public_ip_on_launch = "false"

  lifecycle {
    create_before_destroy = true
  }

  tags = "${concat(local.common_tags, list(
  map("key","Name","value","private-${element(data.aws_availability_zones.available.names, count.index)}")
  ))}"
}

resource "aws_route_table" "public" {
  count  = "1"
  vpc_id = "${aws_vpc.hub.id}"

  tags = "${concat(local.common_tags, list(
  map("key","Name","value","public")
  ))}"
}

resource "aws_route_table" "private" {
  count  = "1"
  vpc_id = "${aws_vpc.hub.id}"

  tags = "${concat(local.common_tags, list(
  map("key","Name","value","private")
  ))}"
}

resource "aws_internet_gateway" "ig_public" {
  count  = "1"
  vpc_id = "${aws_vpc.hub.id}"

  tags = "${concat(local.common_tags, list(
  map("key","Name","value","public")
  ))}"

  depends_on = [
    "aws_vpc.hub",
  ]

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_route_table_association" "public" {
  count = "${length(data.aws_availability_zones.available.names)}"

  subnet_id      = "${element(aws_subnet.public_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.public.id}"
}

resource "aws_route_table_association" "private" {
  count = "${length(data.aws_availability_zones.available.names)}"

  subnet_id      = "${element(aws_subnet.private_subnet.*.id, count.index)}"
  route_table_id = "${aws_route_table.private.id}"
}

resource "aws_route" "private_nat" {
  route_table_id         = "${aws_route_table.private.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.public_nat.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_route" "public_ig" {
  route_table_id         = "${aws_route_table.public.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.ig_public.id}"

  timeouts {
    create = "5m"
  }
}

resource "aws_eip" "nat" {
  count = 1

  tags = "${concat(local.common_tags, list(
  map("key","Name","value","public")
  ))}"
}

resource "aws_nat_gateway" "public_nat" {
  count = "1"

  allocation_id = "${aws_eip.nat.id}"
  subnet_id     = "${element(aws_subnet.public_subnet.*.id, count.index)}"

  tags = "${concat(local.common_tags, list(
  map("Name", "nat")
  ))}"
}
