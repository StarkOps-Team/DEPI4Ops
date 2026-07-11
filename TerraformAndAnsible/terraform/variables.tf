variable "aws_region" {
  default = "us-east-1"
}

variable "project_name" {
  default = "ecommerce-devops"
}

variable "controller_instance_type" {
  description = "Ansible controller only runs ansible, small instance is enough"
  default     = "t2.micro"
}

variable "target_instance_type" {
  description = "Needs 2 vCPU / 2GB+ RAM minimum for kubeadm"
  default     = "t3.medium"
}

variable "allowed_cidr" {
  description = "CIDR allowed to reach the instances. Restrict to your own IP in production (x.x.x.x/32)."
  default     = "0.0.0.0/0"
}
