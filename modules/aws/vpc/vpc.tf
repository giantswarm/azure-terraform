# Following networking schema implemented:
#
#   * a public route table with the internet gateway as a default route
#   * a private route table with the private nat gateway as a default route
#   * bastion and elb subnets are using the public route table
#   * vault and worker subnets are using the private route table
#   * the private nat gateway is in the bastion subnet as well (needs to be in a public subnet)

data "aws_availability_zones" "available" {}

data "aws_region" "current" {}

resource "aws_vpc" "cluster_vpc" {
  cidr_block = "${var.vpc_cidr}"

  enable_dns_support   = true
  enable_dns_hostnames = true

  tags {
    Name        = "${var.cluster_name}"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_internet_gateway" "cluster_vpc" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags {
    Name        = "${var.cluster_name}"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_nat_gateway" "private_nat_gateway_0" {
  allocation_id = "${aws_eip.private_nat_gateway_0.id}"
  subnet_id     = "${aws_subnet.bastion_0.id}"
}

resource "aws_nat_gateway" "private_nat_gateway_1" {
  allocation_id = "${aws_eip.private_nat_gateway_1.id}"
  subnet_id     = "${aws_subnet.bastion_1.id}"
}

resource "aws_eip" "private_nat_gateway_0" {
  vpc = true

  tags {
    Name        = "${var.cluster_name}-private-nat-gateway0"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_eip" "private_nat_gateway_1" {
  vpc = true

  tags {
    Name        = "${var.cluster_name}-private-nat-gateway1"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_route_table" "cluster_vpc_private_0" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags {
    Name        = "${var.cluster_name}_private_0"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_route_table" "cluster_vpc_private_1" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags {
    Name        = "${var.cluster_name}-private1"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_route_table" "cluster_vpc_public_0" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags {
    Name        = "${var.cluster_name}-public0"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_route_table" "cluster_vpc_public_1" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  tags {
    Name        = "${var.cluster_name}-public1"
    Environment = "${var.cluster_name}"
  }
}

resource "aws_route" "vpc_local_route_0" {
  route_table_id         = "${aws_route_table.cluster_vpc_public_0.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.cluster_vpc.id}"
  depends_on             = ["aws_route_table.cluster_vpc_public_0"]
}

resource "aws_route" "vpc_local_route_1" {
  route_table_id         = "${aws_route_table.cluster_vpc_public_1.id}"
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = "${aws_internet_gateway.cluster_vpc.id}"
  depends_on             = ["aws_route_table.cluster_vpc_public_1"]
}

resource "aws_route" "private_nat_gateway_0" {
  route_table_id         = "${aws_route_table.cluster_vpc_private_0.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.private_nat_gateway_0.id}"
}

resource "aws_route" "private_nat_gateway_1" {
  route_table_id         = "${aws_route_table.cluster_vpc_private_1.id}"
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = "${aws_nat_gateway.private_nat_gateway_1.id}"
}

resource "aws_vpc_endpoint" "s3" {
  vpc_id       = "${aws_vpc.cluster_vpc.id}"
  service_name = "com.amazonaws.${data.aws_region.current.name}.s3"

  route_table_ids = [
    "${aws_route_table.cluster_vpc_private_0.id}",
    "${aws_route_table.cluster_vpc_private_1.id}",
    "${aws_route_table.cluster_vpc_public_0.id}",
    "${aws_route_table.cluster_vpc_public_1.id}",
  ]
}

# Deny all traffic in default sec.group.
resource "aws_default_security_group" "default" {
  vpc_id = "${aws_vpc.cluster_vpc.id}"

  # Specifying w/o rules deletes all existing rules
  # https://www.terraform.io/docs/providers/aws/r/default_security_group.html
}
