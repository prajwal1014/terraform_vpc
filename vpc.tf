

resource "aws_vpc" "VPC" {
  cidr_block           = "10.0.0.0/24"
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "VPC"
  }
}

## Public Subnet
resource "aws_subnet" "Pu_SN" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = "10.0.0.0/25"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = true

  tags = {
    Name = "Pu_SN"
  }
}

## Public Instance
resource "aws_instance" "Pu_SN" {
  ami                         = "ami-0f2ce9ce760bd7133"
  instance_type               = "t2.micro"
  key_name                    = "n2025"
  subnet_id                   = aws_subnet.Pu_SN.id
  security_groups             = [aws_security_group.ssg.id]
  associate_public_ip_address = true

  tags = {
    Name = "Pu_SN"
  }

  user_data = file("sample.sh")
}

## Security Group
resource "aws_security_group" "ssg" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "ssg"
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

## Internet Gateway
resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.VPC.id

  tags = {
    Name = "igw"
  }
}

## Public Route Table
resource "aws_route_table" "pu_rt" {
  vpc_id = aws_vpc.VPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = {
    Name = "pu_rt"
  }
}

## Public Route Association
resource "aws_route_table_association" "pu_rt_assoc" {
  subnet_id      = aws_subnet.Pu_SN.id
  route_table_id = aws_route_table.pu_rt.id
}

## Private Subnet
resource "aws_subnet" "Pr_SN" {
  vpc_id                  = aws_vpc.VPC.id
  cidr_block              = "10.0.0.128/25"
  availability_zone       = "ap-south-1a"
  map_public_ip_on_launch = false

  tags = {
    Name = "Pr_SN"
  }
}

## Private Instance
resource "aws_instance" "pvt" {
  ami                         = "ami-0f2ce9ce760bd7133"
  instance_type               = "t2.micro"
  key_name                    = "n2025"
  subnet_id                   = aws_subnet.Pu_SN.id
  security_groups             = [aws_security_group.ssg.id]
  associate_public_ip_address = false

  tags = {
    Name = "pvt"
  }

  user_data = file("sample.sh")
}

## Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.VPC.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.ngw.id
  }

  tags = {
    Name = "private_rt"
  }
}

## Private Route Association
resource "aws_route_table_association" "private_assoc" {
  subnet_id      = aws_subnet.Pr_SN.id
  route_table_id = aws_route_table.private_rt.id
}

## Elastic IP for NAT Gateway
resource "aws_eip" "nat_eip" {
  vpc = true
}

## NAT Gateway
resource "aws_nat_gateway" "ngw" {
  allocation_id = aws_eip.nat_eip.id
  subnet_id     = aws_subnet.Pu_SN.id
  depends_on    = [aws_internet_gateway.igw]

  tags = {
    Name = "ngw"
  }
}

## Outputs
output "internet_gateway" {
  value = aws_internet_gateway.igw.id
}

output "vpc_id" {
  value = aws_vpc.VPC.id
}

output "vpc_cidr_block" {
  value = aws_vpc.VPC.cidr_block
}

output "subnet_id" {
  value = aws_subnet.Pu_SN.id
}

output "subnet_cidr_block" {
  value = aws_subnet.Pu_SN.cidr_block
}
