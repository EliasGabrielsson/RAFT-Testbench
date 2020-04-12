
# ----------------------------------------------------------------------------------------------------------------------
# REQUIRE A SPECIFIC TERRAFORM VERSION OR HIGHER
# This module has been updated with 0.12 syntax, which means it is no longer compatible with any versions below 0.12.
# ----------------------------------------------------------------------------------------------------------------------

terraform {
  required_version = ">= 0.12"
}

resource "aws_key_pair" "deployer" {
  key_name   = "deployer-key"
  public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAABAQCSATZs0y1kW5KFZABfGG7h79agqEzBpXYZotIZd397Hfci2rRslLbren9DDqlt8HXzPTwIkcaDVjPwFjEiJKfh87OnFPk4fwgc9Lxk0a7+Ay+IBSHrErVFNXZ5v2/AMHPH52eYz/VzYsGLKafXb9IRSxzkurUd9cVnQ/7Ogu5Bkovxsmt7agKuKUDJrCHMuoylM1WV84SsfnbIobhQ2IXFXRQQ2K60/ngBURZeSP7BxNfbCwdWjPtifBILjGNrf3oWkSAwdwYFzlaf1bBJTNjYKAalcOFEhcd+XcUQbEzFEUNgmQEqyDlvvx4pKuX+HbeqH31SFDYac5JZKnqVrzUB"
}

locals {
    discovery_url = "${ data.external.etcd_url.result[ "etcd_discovery_url" ] }"
    ignition_etcd3_json_content = "[Unit]\nRequires=coreos-metadata.service\nAfter=coreos-metadata.service\n\n[Service]\nEnvironmentFile=/run/metadata/coreos\nExecStart=\nExecStart=/usr/lib/coreos/etcd-wrapper $ETCD_OPTS \\\n  --listen-peer-urls=\"http://$${COREOS_EC2_IPV4_LOCAL}:2380\" \\\n  --listen-client-urls=\"http://0.0.0.0:2379\" \\\n  --initial-advertise-peer-urls=\"http://$${COREOS_EC2_IPV4_LOCAL}:2380\" \\\n  --advertise-client-urls=\"http://$${COREOS_EC2_IPV4_LOCAL}:2379\" \\\n  --discovery=\"${local.discovery_url}\""
}

/*
 | --
 | -- Run a bash script which only contains a curl command to retrieve
 | -- the etcd discovery url from the service offered by CoreOS.
 | -- This is how to retrieve the URL from any command line.
 | --
 | --     $ curl https://discovery.etcd.io/new?size=3
 | --
*/
data external etcd_url {
    program = [ "python", "${path.module}/etcd3-discovery-url.py", "${ var.in_node_count }" ]
}

provider "aws" {
  profile    = "default"
  region     = "eu-west-1"
}

# NETWORK STUFF


resource "aws_vpc" "lab-net" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "lab-net"
  }
}

resource "aws_eip" "etcd-bootstrap-node-public_ip" {
  instance = aws_instance.etcd-bootstrap-node.id
  vpc      = true
}

resource "aws_eip" "nat-public_ip" {
  vpc      = true
}

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.lab-net.id
  tags = {
    Name = "etcd-lab GW"
  }
}

resource "aws_subnet" "lab-net-sub-public" {
  vpc_id                  = aws_vpc.lab-net.id
  cidr_block              = "10.0.2.0/24"
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_subnet" "lab-net-sub-private" {
  vpc_id                  = aws_vpc.lab-net.id
  cidr_block              = "10.0.1.0/24"
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_nat_gateway" "nat-gateway" {
  subnet_id = aws_subnet.lab-net-sub-public.id
  allocation_id = aws_eip.nat-public_ip.id
  depends_on = [aws_internet_gateway.gw]
}

resource "aws_route_table" "lab-net-sub-private-routetable" {
	vpc_id = aws_vpc.lab-net.id
	route {
		cidr_block = "0.0.0.0/0"
		nat_gateway_id = aws_nat_gateway.nat-gateway.id
	}
  tags = {
    Name = "lab-private-routetable"
  }
}
resource "aws_route_table_association" "routetable-a-1" {
  subnet_id = aws_subnet.lab-net-sub-private.id
  route_table_id = aws_route_table.lab-net-sub-private-routetable.id
}

resource "aws_route_table" "lab-net-sub-public-routetable" {
	vpc_id = aws_vpc.lab-net.id
	route {
		cidr_block = "0.0.0.0/0"
		gateway_id = aws_internet_gateway.gw.id
	}
  tags = {
    Name = "lab-public-routetable"
  }
}
resource "aws_route_table_association" "routetable-a-2" {
  subnet_id = aws_subnet.lab-net-sub-public.id
  route_table_id = aws_route_table.lab-net-sub-public-routetable.id
}

# INSTANCES
resource "aws_instance" "etcd-bootstrap-node" {
  ami           = "ami-07c25af0e918ce3c1"
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.lab-net-sub-public.id
  private_ip    = "10.0.2.100"
  security_groups = [aws_security_group.etcd-io.id]
  user_data       = data.ignition_config.etcd3.rendered
  key_name      = "Mars 2020"
  
}

resource aws_instance etcd-node {
  count         = var.in_node_count - 1
  ami           = "ami-07c25af0e918ce3c1"
  instance_type = "t2.nano"
  subnet_id     = aws_subnet.lab-net-sub-private.id
  security_groups = [aws_security_group.etcd-io.id]
  user_data       = data.ignition_config.etcd3.rendered
  key_name      = "Mars 2020"
  
  depends_on = [aws_instance.etcd-bootstrap-node]
}

/*
 | --
 | -- Visit the terraform ignition user manual at the url below to
 | -- understand how ignition is used as the de-factor cloud-init
 | -- starter for a cluster of CoreOS machines.
 | --
 | --  https://www.terraform.io/docs/providers/ignition/index.html
 | --
*/
data ignition_config etcd3 {
    systemd = [data.ignition_systemd_unit.etcd3.rendered]
}

/*
 | --
 | -- This slice of the ignition configuration deals with the
 | -- systemd service. Once rendered it is then placed alongside
 | -- the other ignition configuration blocks in ignition_config
 | --
*/
data ignition_systemd_unit etcd3 {
    name = "etcd-member.service"
    enabled = "true"
    dropin {
        name = "20-clct-etcd-member.conf"
        content = "${ local.ignition_etcd3_json_content }"
    }
}

resource "aws_security_group" "etcd-io" {
  name        = "etcd-io"
  description = "Allow ports for etcd"
  vpc_id      = aws_vpc.lab-net.id

  ingress {
    description = "http"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "https"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "ssh"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "etcd-1"
    from_port   = 2379
    to_port     = 2380
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "etcd-2"
    from_port   = 4001
    to_port     = 4001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  ingress {
    description = "etcd-3"
    from_port   = 7001
    to_port     = 7001
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
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
