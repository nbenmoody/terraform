terraform {
  required_version = "~> 1.9.0"
  required_providers {
    aws = {
      source = "hashicorp/aws"
      version = "5.55.0"
    }
  }
}

provider "aws" {
  region = "us-east-2"
}


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
  vpc_id = aws_vpc.main.id
  depends_on = [aws_vpc.main]
}

resource "aws_subnet" "main_public_1" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "us-east-2a"

  tags = {
    Name = "main-public-1"
  }
  depends_on = [aws_internet_gateway.main_internet_gateway]
}

resource "aws_subnet" "main_public_2" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
  availability_zone = "us-east-2b"

  tags = {
    Name = "main-public-2"
  }
  depends_on = [aws_internet_gateway.main_internet_gateway]
}

resource "aws_subnet" "main_public_3" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.3.0/24"
  availability_zone = "us-east-2c"

  tags = {
    Name = "main-public-3"
  }
  depends_on = [aws_internet_gateway.main_internet_gateway]
}

resource "aws_key_pair" "cluster_node_key" {
  key_name = "cluster-node-key"
  public_key = file("${path.module}/cluster_node_public_key")
}

resource "aws_instance" "cluster_node_1" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.main_public_1.id
  key_name = aws_key_pair.cluster_node_key.key_name
  
  tags = {
    Name = "cluster-node-1"
  }
  depends_on = [aws_subnet.main_public_1, aws_key_pair.cluster_node_key]
}

resource "aws_instance" "cluster_node_2" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.main_public_2.id
  key_name = aws_key_pair.cluster_node_key.key_name

  tags = {
    Name = "cluster-node-2"
  }
  depends_on = [aws_subnet.main_public_2, aws_key_pair.cluster_node_key]
}

resource "aws_instance" "cluster_node_3" {
  ami           = data.aws_ami.ubuntu.id
  instance_type = "t2.micro"
  associate_public_ip_address = true
  subnet_id = aws_subnet.main_public_3.id
  key_name = aws_key_pair.cluster_node_key.key_name

  tags = {
    Name = "cluster-node-3"
  }
  depends_on = [aws_subnet.main_public_3, aws_key_pair.cluster_node_key]
}
