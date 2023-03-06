resource "aws_vpc" "main-vpc" {
  cidr_block       = var.cidr_blocks
  instance_tenancy = "default"

  tags = {
    "Name" = "one-vpc"
  }
}

resource "aws_subnet" "public" {
  count = length(var.public_cidr_blocks)

  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = var.public_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index]
  tags = {
    Name = "public-${count.index + 1}"
  }
}


resource "aws_subnet" "private" {
  count = length(var.private_cidr_blocks)

  vpc_id            = aws_vpc.main-vpc.id
  cidr_block        = var.private_cidr_blocks[count.index]
  availability_zone = var.availability_zones[count.index % length(var.availability_zones)]
  tags = {
    Name = "private-${var.name_prefix[floor(count.index / 2)]}-${count.index % 2 + 1}"
  }
}

resource "aws_internet_gateway" "gateway" {
  vpc_id = aws_vpc.main-vpc.id

  tags = {
    Name = "main-igw"
  }
}

resource "aws_route_table" "pub-rt" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = var.cidr_blocks_defualt
    gateway_id = aws_internet_gateway.gateway.id
  }

  lifecycle {
    ignore_changes = all
  }

  tags = {
    Name = "public-route"
  }
}

resource "aws_route_table_association" "public-asso" {
  count = length(var.public_cidr_blocks)

  subnet_id      = element(aws_subnet.public.*.id, count.index)
  route_table_id = aws_route_table.pub-rt.id
}

resource "aws_eip" "elasticip" {
  vpc = true
}

resource "aws_nat_gateway" "nat_gateway" {
  allocation_id = aws_eip.elasticip.id
  subnet_id     = aws_subnet.public[0].id

  tags = {
    Name = "nat-gateway"
  }
}

resource "aws_route_table" "private-rt" {
  vpc_id = aws_vpc.main-vpc.id

  route {
    cidr_block = var.cidr_blocks_defualt
    gateway_id = aws_nat_gateway.nat_gateway.id
  }

  lifecycle {
    ignore_changes = all
  }
  tags = {
    Name = "private-route"
  }
}
resource "aws_route_table_association" "private-asso" {
  count = length(var.private_cidr_blocks)

  subnet_id      = element(aws_subnet.private.*.id, count.index)
  route_table_id = aws_route_table.private-rt.id
}
resource "aws_security_group" "main-sg" {
  name   = "main-sg"
  vpc_id = aws_vpc.main-vpc.id

  dynamic "ingress" {
    for_each = [80, 8080, 3306, 22]
    content {
      from_port   = ingress.value
      to_port     = ingress.value
      protocol    = "tcp"
      cidr_blocks = [var.cidr_blocks_defualt]
    }
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.cidr_blocks_defualt]
  }

  tags = {
    "Name" = "main-sg"
  }
}
