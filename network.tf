resource "aws_vpc" "myec2vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
  tags = {
    Name = "MyVPC"
  }
}

resource "aws_subnet" "myec2subnet" {
  vpc_id                  = aws_vpc.myec2vpc.id
  cidr_block              = "10.0.1.0/24"
  availability_zone       = "us-east-1a"
  map_public_ip_on_launch = true
  tags = {
    name = "MyVPC-Subnet"
  }
}

resource "aws_internet_gateway" "myec2igw" {
  vpc_id = aws_vpc.myec2vpc.id
  tags = {
    Name = "MyVPC-IGW"
  }
}

resource "aws_route_table" "myec2rt" {
  vpc_id = aws_vpc.myec2vpc.id
  tags = {
    name = "MyVPC-RT"
  }
}

resource "aws_route" "myec2route" {
  route_table_id         = aws_route_table.myec2rt.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.myec2igw.id
}

resource "aws_route_table_association" "myec2-rt-association" {
  subnet_id      = aws_subnet.myec2subnet.id
  route_table_id = aws_route_table.myec2rt.id
}