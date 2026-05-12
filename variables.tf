variable "aws_region" {
  description = "Région AWS"
  type        = string
  default     = "us-east-1"
}

variable "vpc_cidr" {
  description = "CIDR du VPC"
  type        = string
  default     = "192.168.0.0/16"
}

variable "project_name" {
  description = "Nom du projet"
  type        = string
  default     = "terraform-project"
}

variable "instance_type" {
  description = "Type d'instance EC2"
  type        = string
  default     = "t2.micro"
}

variable "key_name" {
  description = "Nom de la clé SSH"
  type        = string
  default     = "key"
}

variable "ami_bastion" {
  description = "AMI pour le bastion"
  type        = string
  default     = "ami-0182f373e66f89c85"
}

variable "ami_app" {
  description = "AMI pour les applications"
  type        = string
  default     = "ami-013efd7d9f40467af"
}