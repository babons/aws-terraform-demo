resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
  
  tags   = {
    Terraform = "true"
    Environment = "dev"
  }
}

resource "aws_subnet" "public" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-1a"

  tags = {
    name        = "Public Subnet"
    terraform   = "true"
    environment = "dev"
  }
}

resource "aws_subnet" "private" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-1a"

  tags = {
    name        = "Private Subnet"
    terraform   = "true"
    environment = "dev"
  }
}

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.main.id

  tags = {
    name       = "main-igw"
    terraform  = "true"
    environemt = "dev"
  }
}

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name        = "pubic-rt"
    terraform   = "true"
    environment = "dev"
  }
}