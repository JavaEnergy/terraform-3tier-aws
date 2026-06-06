variable "project_name" {
  type = string
}

variable "environment" {
  type = string
}

variable "vpc_cidr" {
  type = string
}

variable "availability_zones" {
  type = list(string)
}

variable "public_subnet_cidrs" {
  type = list(string)
}

variable "ecs_subnet_cidrs" {
  type = list(string)
}

variable "rds_subnet_cidrs" {
  type = list(string)
}

variable "region_label" {
  description = "Short label for naming: primary or secondary"
  type        = string
}
