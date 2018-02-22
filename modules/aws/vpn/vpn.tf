# site2site vpn for access to bastion

variable "aws_customer_gateway_id" {}
variable "aws_external_ipsec_subnet" {}
variable "aws_vpn_name" {}
variable "aws_vpn_vpc_id" {}

variable "aws_public_route_table_ids" {
  type = "list"
}

resource "aws_vpn_gateway" "vpn_gw" {
  count  = "${var.aws_customer_gateway_id == "" ? 0 : 1}"
  vpc_id = "${var.aws_vpn_vpc_id}"

  tags {
    Name        = "${var.aws_vpn_name}"
    Environment = "${var.aws_vpn_name}"
  }
}

resource "aws_vpn_connection" "aws_vpn_conn" {
  count               = "${var.aws_customer_gateway_id == "" ? 0 : 1}"
  vpn_gateway_id      = "${aws_vpn_gateway.vpn_gw.*.id[count.index]}"
  customer_gateway_id = "${var.aws_customer_gateway_id}"
  type                = "ipsec.1"
  static_routes_only  = true

  tags {
    Name        = "${var.aws_vpn_name}"
    Environment = "${var.aws_vpn_name}"
  }
}

resource "aws_vpn_connection_route" "customer_network" {
  count                  = "${var.aws_customer_gateway_id == "" ? 0 : 1}"
  destination_cidr_block = "${var.aws_external_ipsec_subnet}"
  vpn_connection_id      = "${aws_vpn_connection.aws_vpn_conn.*.id[count.index]}"
}

# Add vpc routes that point to VPN gateways.
resource "aws_route" "vpc_route" {
  count                  = "${var.aws_customer_gateway_id == "" ? 0 : 2}"
  route_table_id         = "${var.aws_public_route_table_ids[count.index]}"
  destination_cidr_block = "${var.aws_external_ipsec_subnet}"
  gateway_id             = "${aws_vpn_gateway.vpn_gw.id}"
}