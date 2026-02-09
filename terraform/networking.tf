# Get default VPC
data "aws_vpc" "default" {
  default = true
}

# Get public subnets in default VPC
data "aws_subnets" "default" {
  filter {
    name   = "vpc-id"
    values = [data.aws_vpc.default.id]
  }
}

# Pick first subnet for NAT Gateway and Glue
data "aws_subnet" "first" {
  id = data.aws_subnets.default.ids[0]
}

# Security group for Glue
resource "aws_security_group" "glue" {
  name   = "vantagepoint-glue-sg"
  vpc_id = data.aws_vpc.default.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  egress {
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }
}

# Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
  domain = "vpc"
}

# NAT Gateway in public subnet
resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = data.aws_subnet.first.id
}

# Private subnet for Glue
resource "aws_subnet" "glue_private" {
  vpc_id            = data.aws_vpc.default.id
  cidr_block        = "172.31.96.0/24"
  availability_zone = data.aws_subnet.first.availability_zone
}

# Route table for private subnet
resource "aws_route_table" "glue_private" {
  vpc_id = data.aws_vpc.default.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.main.id
  }
}

resource "aws_route_table_association" "glue_private" {
  subnet_id      = aws_subnet.glue_private.id
  route_table_id = aws_route_table.glue_private.id
}
