# Note: This Terraform is to demostrate the provisioning of a three-tier application using AWS EC2 ASG, ELB and RDS database
# The code will normnally have the accompanying variable.tf, terraform.tfvar and output.tf. However, I am leaving those files out for simplicity.
# Also note that the provided code is roughly 10% to 30% of what is required in a real-lfe situation.

data "aws_ami" "ubuntu-ami" {
  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-trusty-20.04-amd64-server-*"]
  }

  most_recent = true
  owners      = ["099720109477"]

}

# Root volume defaults of 20 unless otherwise specified
locals {
  default_root_volume_size = "20"
  this_root_volume_size    = "${var.custom_root_vol_size != "" ? var.custom_root_vol_size : local.default_root_volume_size}"
}

################################################
# EC2 Autoscaling Launch Config
################################################

resource "aws_launch_configuration" "middle-tier-ec2-launch-config" {
  iam_instance_profile        = "${var.ec2-role}"
  image_id                    = "${data.aws_ami.ubuntu-ami.id}"
  instance_type               = "c5.medium"
  security_groups             = ["${var.security_group_ids}"]
  user_data                   = "${file("${path.root}/${var.bootstrap_file}")}"
  key_name                    = "${var.ssh_key_name}"

 root_block_device {
    volume_type           = "gp2"
    volume_size           = "${local.this_root_volume_size}"
    delete_on_termination = "true"
  }

  lifecycle {
    create_before_destroy = true
  }
}

################################################
# Autoscaling Group
################################################

resource "aws_autoscaling_group" "middle-tier-asg" {
  desired_capacity     = "${var.worker_autoscale_desired_capacity}"
  launch_configuration = "${aws_launch_configuration.middle-tier-ec2-launch-config.id}"
  max_size             = "${var.worker_autoscale_max_size}"
  min_size             = "${var.worker_autoscale_min_size}"
  name                 = "challenge-1-node"
  vpc_zone_identifier  = [aws_subnet.example1.id, aws_subnet.example2.id]
  target_group_arns    = "${aws_lb_target_group.challenge-1-target_group.arn}"

  tag {
    key                 = "Name"
    value               = "challenge-1-node"
    propagate_at_launch = true
  }

}

# Elastic Load Balancer
# This code sample does not provide aws_lb_listener, aws_lb_listener_certificate
resource "aws_lb" "challenge-1-alb" {
  name               = "challenge-1-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = ["${var.alb-security_groups}"]
  subnets            = ["${var.subnets}"]

  enable_deletion_protection = true

  tags = {
    Name        = "${var.service_name}-alb-${var.environment_name}-${var.aws_region_suffix}"
    Environment = "${var.environment_name}"
  }
}

resource "aws_lb_target_group" "challenge-1-target_group" {
  name     = "challenge-1-target_group"
  port     = 80
  protocol = "HTTP"
}


# RDS database
resource "aws_db_instance" "rds-instance" {
  count = "${length(var.rds_resources)}"

  identifier        = "${lookup(var.rds_resources[count.index], "identifier")}"
  engine            = "${var.engine}"
  engine_version    = "${var.engine_version}"
  instance_class    = "${lookup(var.rds_resources[count.index], "instance_class")}"
  allocated_storage = "${lookup(var.rds_resources[count.index], "allocated_storage")}"
  storage_type      = "${var.storage_type}"
  storage_encrypted = "${var.storage_encrypted}"

  name     = "${var.database_name}"
  username = "${var.username}"
  password = "${var.password}"
  port     = "${var.port}"

  snapshot_identifier    = "${var.snapshot_identifier}"
  vpc_security_group_ids = ["${var.vpc_security_group_ids}"]
  db_subnet_group_name   = "${var.db_subnet_group_name}"
  parameter_group_name   = "${lookup(var.rds_resources[count.index], "parameter_group")}"

  availability_zone   = "${var.availability_zone}"
  multi_az            = "${var.multi_az["${var.environment_name}"]}"
  iops                = "${var.iops}"
  publicly_accessible = "${var.publicly_accessible}"

  allow_major_version_upgrade     = "${var.allow_major_version_upgrade}"
  maintenance_window              = "${var.maintenance_window["${var.aws_region}"]}"
  copy_tags_to_snapshot           = "${var.copy_tags_to_snapshot}"
  final_snapshot_identifier       = "${var.final_snapshot_identifier}"
  backup_retention_period         = "${var.backup_retention_period}"
  backup_window                   = "${var.backup_window["${var.aws_region}"]}"
  timeouts                        = "${var.timeouts}"

  tags = {
    "Environment" = "${var.environment_name}"
    "Service"     = "${var.service_name}"
  }
}
