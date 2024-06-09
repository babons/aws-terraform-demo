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

resource "aws_vpc_security_group_ingress_rule" "alb_allow_http" {
  security_group_id = aws_security_group.alb_allow_http.id
  cidr_ipv4         = aws_vpc.main.cidr_block
  from_port         = 443
  ip_protocol       = "tcp"
  to_port           = 443
}

resource "aws_vpc_security_group_egress_rule" "alb_allow_http" {
  security_group_id = aws_security_group.alb_allow_http.id
  cidr_ipv4         = "0.0.0.0/0"
  ip_protocol       = "tcp"
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
