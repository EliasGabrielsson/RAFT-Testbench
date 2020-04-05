
# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

provider "aws" {
  profile    = "default"
  region     = "eu-west-1"
}

# module "containers" {
#   source = "./modules/cluster-node"
# }

resource "aws_eip" "etcd-bootstrap-node-public_ip" {
  instance = "${aws_instance.etcd-bootstrap-node.id}"
  vpc      = true
}

resource "aws_instance" "etcd-bootstrap-node" {
  ami           = "ami-07c25af0e918ce3c1"
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.lab-net-sub.id
  private_ip    = "10.0.0.100"
  security_groups = [aws_security_group.etcd-io.id]
  
}

resource aws_instance etcd-node {
  ami           = "ami-07c25af0e918ce3c1"
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.lab-net-sub.id
  security_groups = [aws_security_group.etcd-io.id]
  count         = 5

  depends_on = [aws_instance.etcd-bootstrap-node]
}

resource "aws_vpc" "lab-net" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "lab-net"
  }
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.lab-net.id
  tags = {
    Name = "etcd-lab GW"
  }
}

resource "aws_subnet" "lab-net-sub" {
  vpc_id                  = "${aws_vpc.lab-net.id}"
  cidr_block              = "10.0.0.0/16"

  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "etcd-lab-routetable" {
	vpc_id = aws_vpc.lab-net.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.gw.id
	}

  tags = {
    Name = "etcd-lab-routetable"
  }
}
resource "aws_route_table_association" "etcd-lab-routetable-a" {
  subnet_id = aws_subnet.lab-net-sub.id
  route_table_id = aws_route_table.etcd-lab-routetable.id
}


resource "aws_security_group" "etcd-io" {
  name        = "etcd-io"
  description = "Allow ports for etcd"
  vpc_id      = aws_vpc.lab-net.id

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "etcd"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.lab-net.cidr_block]
  }

  ingress {
    description = "etcd"
    from_port   = 4001
    to_port     = 4001
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.lab-net.cidr_block]
  }

  ingress {
    description = "etcd"
    from_port   = 7001
    to_port     = 7001
    protocol    = "tcp"
    cidr_blocks = [aws_vpc.lab-net.cidr_block]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "etcd-io"
  }
}
