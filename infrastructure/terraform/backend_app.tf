resource "aws_lb" "backend" {
  name               = "${local.name_prefix}-backend-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb.id]
  subnets            = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-backend-alb"
  })
}

resource "aws_lb_target_group" "backend" {
  name     = "${local.name_prefix}-backend-tg"
  port     = var.backend_port
  protocol = "HTTP"
  vpc_id   = aws_vpc.main.id

  health_check {
    enabled             = true
    path                = "/"
    matcher             = "200-399"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 2
    unhealthy_threshold = 3
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-backend-tg"
  })
}

resource "aws_lb_listener" "backend_http" {
  load_balancer_arn = aws_lb.backend.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.backend.arn
  }
}

resource "aws_launch_template" "backend" {
  name_prefix   = "${local.name_prefix}-backend-"
  image_id      = data.aws_ami.ubuntu.id
  instance_type = var.instance_type

  iam_instance_profile {
    name = aws_iam_instance_profile.backend_ec2.name
  }

  vpc_security_group_ids = [aws_security_group.backend.id]

  user_data = base64encode(templatefile("${path.module}/templates/backend-user-data.sh.tpl", {
    backend_port              = var.backend_port
    mongo_uri_parameter_name  = var.mongo_uri_parameter_name
    jwt_secret_parameter_name = var.jwt_secret_parameter_name
    redis_addr                = "${aws_elasticache_cluster.redis.cache_nodes[0].address}:6379"
    cloudwatch_log_group      = aws_cloudwatch_log_group.backend.name
    aws_region                = var.aws_region
  }))

  tag_specifications {
    resource_type = "instance"

    tags = merge(local.common_tags, {
      Name = "${local.name_prefix}-backend"
    })
  }

  tags = merge(local.common_tags, {
    Name = "${local.name_prefix}-backend-launch-template"
  })
}

resource "aws_autoscaling_group" "backend" {
  name                = "${local.name_prefix}-backend-asg"
  desired_capacity    = 1
  min_size            = 1
  max_size            = 2
  vpc_zone_identifier = [aws_subnet.public_a.id, aws_subnet.public_b.id]

  target_group_arns = [aws_lb_target_group.backend.arn]
  health_check_type = "ELB"

  launch_template {
    id      = aws_launch_template.backend.id
    version = "$Latest"
  }

  tag {
    key                 = "Name"
    value               = "${local.name_prefix}-backend-asg"
    propagate_at_launch = false
  }

  tag {
    key                 = "Project"
    value               = var.project_name
    propagate_at_launch = true
  }

  tag {
    key                 = "Environment"
    value               = var.environment
    propagate_at_launch = true
  }
}
