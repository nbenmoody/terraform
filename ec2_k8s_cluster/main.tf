terraform {
  required_version = "~> 1.9.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "5.55.0"
    }
    ansible = {
      source = "ansible/ansible"
      version = "1.3.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}

provider "ansible" {
}

# --------- AWS --------------
data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_vpc" "main" {
  cidr_block       = "10.0.0.0/16"
  instance_tenancy = "default"

  tags = {
    Name = "main"
  }
}

resource "aws_internet_gateway" "main_internet_gateway" {
  vpc_id     = aws_vpc.main.id
  depends_on = [aws_vpc.main]
}

resource "aws_subnet" "main_public_1" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "main-public-1"
  }
  depends_on = [aws_internet_gateway.main_internet_gateway]
}

resource "aws_subnet" "main_public_2" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.2.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "main-public-2"
  }
  depends_on = [aws_internet_gateway.main_internet_gateway]
}

resource "aws_subnet" "main_public_3" {
  vpc_id            = aws_vpc.main.id
  cidr_block        = "10.0.3.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name = "main-public-3"
  }
  depends_on = [aws_internet_gateway.main_internet_gateway]
}

resource "aws_route_table" "main_route_table" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main_internet_gateway.id
  }

  tags = {
    Name = "main-route-table"
  }
}

resource "aws_route_table_association" "main_public_1" {
  subnet_id      = aws_subnet.main_public_1.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_route_table_association" "main_public_2" {
  subnet_id      = aws_subnet.main_public_2.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_route_table_association" "main_public_3" {
  subnet_id      = aws_subnet.main_public_3.id
  route_table_id = aws_route_table.main_route_table.id
}

resource "aws_security_group" "cluster_security_group" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port = 0
    to_port   = 0
    protocol  = "-1"
    self      = true
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Name = "cluster-security-group"
  }
}

resource "aws_key_pair" "cluster_node_key" {
  key_name   = "cluster-node-key"
  public_key = file("${path.module}/cluster_node_public_key")
}

locals {
  instances = {
    cluster_node_1 = {
      subnet_id = aws_subnet.main_public_1.id
      tags = {
        Name = "cluster-node-1"
      }
    }
    cluster_node_2 = {
      subnet_id = aws_subnet.main_public_2.id
      tags = {
        Name = "cluster-node-2"
      }
    }
    cluster_node_3 = {
      subnet_id = aws_subnet.main_public_3.id
      tags = {
        Name = "cluster-node-3"
      }
    }
  }
}

resource "aws_instance" "cluster_nodes" {
  for_each                    = local.instances
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = each.value.subnet_id
  key_name                    = aws_key_pair.cluster_node_key.key_name
  security_groups             = [aws_security_group.cluster_security_group.id]
  tags                        = each.value.tags
}

resource "aws_instance" "admin_node" {
  ami                         = data.aws_ami.ubuntu.id
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  subnet_id                   = aws_subnet.main_public_1.id
  key_name                    = aws_key_pair.cluster_node_key.key_name
  security_groups             = [aws_security_group.cluster_security_group.id]
  tags = {
    Name = "admin-node"
  }
}

# --------- Ansible --------------

## Cluster Nodes
resource "ansible_group" "cluster_nodes" {
  name     = "clusterNodes"
}

resource "ansible_host" "cluster_nodes" {
  for_each = aws_instance.cluster_nodes
  name   = each.value.public_ip
  groups = [ansible_group.cluster_nodes.name]
}

resource "ansible_playbook" "cluster_node_playbook" {
  for_each = aws_instance.cluster_nodes
  playbook   = "ansible/cluster-node.yml"
  name       = "cluster-node-configuration"
  groups     = [ansible_group.cluster_nodes.name]
  replayable = true
}

## Admin Node
resource "ansible_group" "admin_nodes" {
  name     = "adminNodes"
}

resource "ansible_host" "admin_node" {
  for_each = aws_instance.cluster_nodes
  name   = each.value.public_ip
  groups = [ansible_group.admin_nodes.name]
}

resource "ansible_playbook" "admin_node_playbook" {
  playbook   = "ansible/admin-node.yml"
  name       = "admin-node-configuration"
  groups     = [ansible_group.admin_nodes.name]
  replayable = true
}
