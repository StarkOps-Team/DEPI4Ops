terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    tls = {
      source  = "hashicorp/tls"
      version = "~> 4.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

data "aws_ami" "ubuntu" {
  most_recent = true
  owners      = ["099720109477"] # Canonical

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

# SSH key generated for both instances

resource "tls_private_key" "ssh_key" {
  algorithm = "RSA"
  rsa_bits  = 4096
}

resource "aws_key_pair" "deployer" {
  key_name   = "${var.project_name}-key"
  public_key = tls_private_key.ssh_key.public_key_openssh
}

resource "local_file" "private_key" {
  content         = tls_private_key.ssh_key.private_key_pem
  filename        = "${path.module}/${var.project_name}-key.pem"
  file_permission = "0600"
}

# Security group

resource "aws_security_group" "devops_sg" {
  name        = "${var.project_name}-sg"
  description = "SSH, HTTP, K8s API, NodePort range"

  ingress {
    description = "SSH"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "HTTP"
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "HTTPS"
    from_port   = 443
    to_port     = 443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "Kubernetes API server"
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "NodePort range"
    from_port   = 30000
    to_port     = 32767
    protocol    = "tcp"
    cidr_blocks = [var.allowed_cidr]
  }

  ingress {
    description = "Internal cluster traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    self        = true
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = { Name = "${var.project_name}-sg" }
}

# Ansible controller

resource "aws_instance" "controller" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.controller_instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  root_block_device {
    volume_size = 20
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-ansible-controller"
    Role = "controller"
  }

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y software-properties-common
              add-apt-repository --yes --update ppa:ansible/ansible
              apt-get install -y ansible python3-pip
              mkdir -p /home/ubuntu/.ssh
              chown ubuntu:ubuntu /home/ubuntu/.ssh
              chmod 700 /home/ubuntu/.ssh
              EOF
}

# Target node (docker + k8s)

resource "aws_instance" "target" {
  ami                    = data.aws_ami.ubuntu.id
  instance_type          = var.target_instance_type
  key_name               = aws_key_pair.deployer.key_name
  vpc_security_group_ids = [aws_security_group.devops_sg.id]

  root_block_device {
    volume_size = 30
    volume_type = "gp3"
  }

  tags = {
    Name = "${var.project_name}-target"
    Role = "target"
  }
}

# Generate ansible inventory locally

resource "local_file" "inventory" {
  content = templatefile("${path.module}/templates/inventory.tpl", {
    target_ip = aws_instance.target.public_ip
  })
  filename = "${path.module}/../ansible/inventory.ini"
}

# Push the private key + inventory onto the controller so it can reach the target

resource "null_resource" "provision_controller" {
  depends_on = [aws_instance.controller, aws_instance.target, local_file.inventory]

  connection {
    type        = "ssh"
    user        = "ubuntu"
    private_key = tls_private_key.ssh_key.private_key_pem
    host        = aws_instance.controller.public_ip
  }

  provisioner "file" {
    content     = tls_private_key.ssh_key.private_key_pem
    destination = "/home/ubuntu/.ssh/target-key.pem"
  }

  provisioner "file" {
    source      = "${path.module}/../ansible/inventory.ini"
    destination = "/home/ubuntu/inventory.ini"
  }

  provisioner "file" {
    source      = "${path.module}/../ansible/playbook.yml"
    destination = "/home/ubuntu/playbook.yml"
  }

  provisioner "file" {
    source      = "${path.module}/../ansible/ansible.cfg"
    destination = "/home/ubuntu/ansible.cfg"
  }

  provisioner "remote-exec" {
    inline = [
      "chmod 600 /home/ubuntu/.ssh/target-key.pem",
      "echo 'Waiting for cloud-init on controller to finish...'",
      "cloud-init status --wait || true"
    ]
  }
}
