resource "aws_subnet" "elb" {
  count = "${length(var.subnet_elb)}"

  vpc_id            = "${aws_vpc.cluster_vpc.id}"
  availability_zone = "${element(data.aws_availability_zones.available.names,count.index)}"
  cidr_block        = "${element(var.subnet_elb, count.index)}"

  tags = "${merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-elb${count.index}"
    )
  )}"
}

resource "aws_route_table_association" "elb" {
  count = "${length(var.subnet_elb)}"

  subnet_id      = "${element(aws_subnet.elb.*.id, count.index)}"
  route_table_id = "${element(aws_route_table.cluster_vpc_public.*.id, count.index}"
}
