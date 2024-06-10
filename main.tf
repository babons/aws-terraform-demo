# --------- VPC Config w/ Subnets, Interney Gateway, and Routes ---------

resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_subnet" "pub1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Public 1"
  }
}

resource "aws_subnet" "pub2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Public 2"
  }
}

resource "aws_subnet" "priv1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-1a"

  tags = {
    Name = "Private 1"
  }
}

resource "aws_subnet" "priv2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.4.0/24"
  availability_zone = "us-east-1b"

  tags = {
    Name = "Private 2"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "Main Internet Gateway"
  }
}

resource "aws_internet_gateway_attachment" "gw-main" {
  internet_gateway_id = aws_internet_gateway.gw.id
  vpc_id = aws_vpc.main.id
}

resource "aws_route_table" "rt-main" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "rt-pub1" {
  subnet_id      = aws_subnet.pub1.id
  route_table_id = aws_route_table.rt-main.id
}

resource "aws_route_table_association" "rt-pub2" {
  subnet_id      = aws_subnet.pub2.id
  route_table_id = aws_route_table.rt-main.id
}

# --------- ALB Security Group ---------

resource "aws_security_group" "alb_allow_http" {
  name        = "alb_allow_http"
  description = "Allow HTTP for all inbound and outbound traffic through ALB."
  vpc_id      = aws_vpc.main.id

  tags = {
    Name = "Allow HTTP ALB"
  }
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_http" {
  security_group_id = aws_security_group.alb_allow_http.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 80
  ip_protocol       = "tcp"
  to_port           = 80
}

resource "aws_vpc_security_group_ingress_rule" "alb_allow_https" {
  security_group_id = aws_security_group.alb_allow_http.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_allow_http" {
  security_group_id = aws_security_group.alb_allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "-1"
}

# --------- EC2-ALB Security Group ---------

resource "aws_security_group" "ec2-allow-alb" {
  name        = "ec2-allow-alb"
  description = "Allow traffic between EC2 instances and ALB."
  vpc_id      = aws_vpc.main.id

  ingress {
    protocol        = "tcp"
    from_port       = 80
    to_port         = 80
    security_groups = [aws_security_group.alb_allow_http.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "Allow EC2 to ALB"
  }
}

# --------- Launch Templates ---------

resource "aws_launch_template" "ec2-web" {
  name          = "ec2-web"
  image_id      = "ami-04b70fa74e45c3917"
  instance_type = "t2.micro"
  key_name      = "ec2-web-01"

  network_interfaces {
    security_groups = [aws_security_group.ec2-allow-alb.id]
  }

  user_data = "PDwtRU9GCiAgICAgICAgICAgICAgIyEvYmluL2Jhc2gKICAgICAgICAgICAgICBhcHQgaW5zdGFsbCAteSBodHRwZAogICAgICAgICAgICAgIHN5c3RlbWN0bCBlbmFibGUgaHR0cGQKICAgICAgICAgICAgICBzeXN0ZW1jdGwgc3RhcnQgaHR0cGQKICAgICAgICAgICAgICBlY2hvICJIZWxsbywgV29ybGQiID4gL3Zhci93d3cvaHRtbC9pbmRleC5odG1sCiAgICAgICAgICAgICAgRU9G"
}

# --------- Autoscaling Groups ---------

resource "aws_autoscaling_group" "app_deployment" {
  name                = "app-deployment"
  max_size            = 5
  min_size            = 2
  desired_capacity    = 4
  vpc_zone_identifier = [aws_subnet.priv1.id, aws_subnet.priv2.id]
  
  launch_template {
    id = aws_launch_template.ec2-web.id
  } 
}

resource "aws_autoscaling_policy" "app_deployment_policy" {
  name                   = "app-deployment-policy"
  scaling_adjustment     = 4
  adjustment_type        = "ChangeInCapacity"
  cooldown               = 300
  autoscaling_group_name = aws_autoscaling_group.app_deployment.name
}

# --------- ALB Configuration ---------

resource "aws_lb" "app_alb" {
  name               = "app-alb"
  internal           = false
  load_balancer_type = "application"
  security_groups    = [aws_security_group.alb_allow_http.id]
  subnets            = [aws_subnet.pub1.id, aws_subnet.pub2.id]
}

resource "aws_lb_target_group" "alb_pub_tg" {
  name        = "alb-pub-tg"
  port        = 80
  protocol    = "HTTP"
  vpc_id      = aws_vpc.main.id
  target_type = "instance"
  health_check {
    path                = "/"
    interval            = 30
    timeout             = 5
    healthy_threshold   = 5
    unhealthy_threshold = 2
  }
}

resource "aws_lb_listener" "ab_pub_listener" {
  load_balancer_arn = aws_lb.app_alb.arn
  port              = 80
  protocol          = "HTTP"

  default_action {
    type             = "forward"
    target_group_arn = aws_lb_target_group.alb_pub_tg.arn
  }
}

# --------- CloudWatch Configuration ---------

resource "aws_cloudwatch_metric_alarm" "app_cloudwatch_alarm_greater" {
  alarm_name                = "app-cpu-util"
  alarm_actions             = [aws_autoscaling_policy.app_deployment_policy.arn]
  metric_name               = "CPUUtilization"
  comparison_operator       = "GreaterThanOrEqualToThreshold"
  evaluation_periods        = 2
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 70
  alarm_description         = "This merics describes EC2 CPU utilization."
  insufficient_data_actions = []
  
  dimensions = {
    autoscaling_group_name = aws_autoscaling_group.app_deployment.name
  }
}

resource "aws_cloudwatch_metric_alarm" "app_cloudwatch_alarm_less" {
  alarm_name                = "app-cpu-util"
  alarm_actions             = [aws_autoscaling_policy.app_deployment_policy.arn]
  metric_name               = "CPUUtilization"
  comparison_operator       = "LessThanOrEqualToThreshold"
  evaluation_periods        = 2
  namespace                 = "AWS/EC2"
  period                    = 120
  statistic                 = "Average"
  threshold                 = 30
  alarm_description         = "This metrics describes EC2 CPU utilization."
  insufficient_data_actions = []
  
  dimensions = {
    autoscaling_group_name = aws_autoscaling_group.app_deployment.name
  }
}