locals {
  common_tags = "${map(
    "giantswarm.io/installation", "${var.cluster_name}",
    "kubernetes.io/cluster/${var.cluster_name}", "owned"
  )}"
}

data "aws_availability_zones" "available" {}


resource "aws_cloudformation_stack" "master_asg" {
  count = var.master_count
  name  = "${var.cluster_name}-master-${count.index}"

  template_body = <<EOF
{
  "Resources": {
    "AutoScalingGroup": {
      "Type": "AWS::AutoScaling::AutoScalingGroup",
      "Properties": {
        "DesiredCapacity": "1",
        "HealthCheckType": "EC2",
        "HealthCheckGracePeriod": 300,
        "LaunchConfigurationName": "${element(aws_launch_configuration.master.*.name, count.index)}",
        "LoadBalancerNames": [
          "${var.cluster_name}-public-master-api",
          "${var.cluster_name}-private-master-api"
        ],
        "MaxSize": "1",
        "DesiredCapacity": "1",
        "MinSize": "1",
        "Tags": [
          {
            "Key": "Name",
            "Value": "${var.cluster_name}-master-${count.index}",
            "PropagateAtLaunch": true
          },
          {
            "Key": "giantswarm.io/installation",
            "Value": "${var.cluster_name}",
            "PropagateAtLaunch": true
          },
          {
            "Key": "kubernetes.io/cluster/${var.cluster_name}",
            "Value": "owned",
            "PropagateAtLaunch": true
          }
        ],
        "VPCZoneIdentifier": ["${var.master_subnet_ids[count.index]}"]
      },
      "UpdatePolicy": {
        "AutoScalingRollingUpdate": {
          "MinInstancesInService": "0",
          "MaxBatchSize": "1",
          "PauseTime": "PT5M"
        }
      }
    }
  },
  "Outputs": {
    "AsgName": {
      "Description": "The name of the auto scaling group",
      "Value": {
        "Ref": "AutoScalingGroup"
      }
    }
  }
}
EOF
}

resource "aws_launch_configuration" "master" {
  count                = var.master_count
  name_prefix          = "${var.cluster_name}-master-"
  iam_instance_profile = element(aws_iam_instance_profile.master.*.name, count.index)
  image_id             = var.container_linux_ami_id
  instance_type        = var.instance_type
  security_groups      = ["${aws_security_group.master.id}"]

  lifecycle {
    create_before_destroy = true
  }

  associate_public_ip_address = false

  root_block_device {
    volume_type = var.volume_type
    volume_size = var.volume_size_root
  }

  # Docker volume.
  ebs_block_device {
    device_name           = var.volume_docker
    delete_on_termination = true
    volume_type           = var.volume_type
    volume_size           = var.volume_size_docker
  }

  user_data = element(data.ignition_config.s3.*.rendered, count.index)
}

resource "aws_ebs_volume" "master_etcd" {
  count = var.master_count

  availability_zone = element(data.aws_availability_zones.available.names, count.index)
  size              = var.volume_size_etcd
  type              = var.volume_type

  tags = merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-master${count.index + 1}-etcd"
    )
  )
}

resource "aws_security_group" "master" {
  name   = "${var.cluster_name}-master"
  vpc_id = var.vpc_id

  # Allow all outbound traffic
  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Allow access from vpc
  ingress {
    from_port   = 10
    to_port     = 65535
    protocol    = "tcp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow access from vpc
  ingress {
    from_port   = 10
    to_port     = 65535
    protocol    = "udp"
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  # Allow IPIP traffic from vpc
  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = 4
    cidr_blocks = ["${var.vpc_cidr}"]
  }

  tags = merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-master"
    )
  )
}

resource "aws_route53_record" "master" {
  count   = var.route53_enabled ? var.master_count : 0
  zone_id = var.dns_zone_id
  name    = "master${count.index + 1}"
  type    = "A"
  records = ["${element(var.master_eni_ips, count.index)}"]
  ttl     = "30"
}

resource "aws_route53_record" "etcd" {
  count   = var.route53_enabled ? var.master_count : 0
  zone_id = var.dns_zone_id
  name    = "etcd${count.index + 1}"
  type    = "A"
  records = ["${element(var.master_eni_ips, count.index)}"]
  ttl     = "30"
}

resource "aws_network_interface" "master" {
  count       = var.master_count
  subnet_id   = element(var.master_subnet_ids, count.index)
  private_ips = ["${element(var.master_eni_ips, count.index)}"]
  security_groups = ["${aws_security_group.master.id}"]

  tags = merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-master${count.index + 1}-etcd"
    )
  )

}

# To avoid 16kb user_data limit upload CoreOS ignition config to a s3 bucket.
# Ignition supports s3 out-of-the-box.
resource "aws_s3_bucket_object" "ignition_master_with_tags" {
  count   = var.s3_bucket_tags ? var.master_count : 0
  bucket  = var.ignition_bucket_id
  key     = "${var.cluster_name}-ignition-master${count.index + 1}.json"
  content = var.user_data[count.index]
  acl     = "private"

  server_side_encryption = "AES256"

  tags = merge(
    local.common_tags,
    map(
      "Name", "${var.cluster_name}-ignition-master"
    )
  )
}

# To avoid 16kb user_data limit upload CoreOS ignition config to a s3 bucket.
# Ignition supports s3 out-of-the-box.
resource "aws_s3_bucket_object" "ignition_master_without_tags" {
  count   = var.s3_bucket_tags ? 0 : var.master_count
  bucket  = var.ignition_bucket_id
  key     = "${var.cluster_name}-ignition-master${count.index + 1}.json"
  content = var.user_data[count.index]
  acl     = "private"

  server_side_encryption = "AES256"
}

locals {
  # In China there is no tags for s3 buckets
  s3_ignition_master_keys = "${concat(aws_s3_bucket_object.ignition_master_with_tags.*.key, aws_s3_bucket_object.ignition_master_without_tags.*.key)}"
}

data "ignition_config" "s3" {
  count = var.master_count

  replace {
    source       = "${format("s3://%s/%s", var.ignition_bucket_id, element(local.s3_ignition_master_keys, count.index))}"
    verification = "sha512-${sha512(var.user_data[count.index])}"
  }
}
