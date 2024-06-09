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
    gateway_id = aws_internet_gateway.gw-main.id
  }
}

resource "aws_route_table_association" "rt-pub" {
  subnet_id = aws_subnet.pub1.id
  route_table_id = aws_route_table.rt-main
}

resource "aws_route_table_association" "rt-pub" {
  subnet_id = aws_subnet.pub2
  route_table_id = aws_route_table.rt-main
}