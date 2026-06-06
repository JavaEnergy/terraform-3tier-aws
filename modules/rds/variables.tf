variable "project_name" { type = string }
variable "environment" { type = string }
variable "region_label" { type = string }
variable "vpc_id" { type = string }
variable "subnet_ids" { type = list(string) }
variable "ecs_subnet_cidrs" {
  description = "ECS subnet CIDRs allowed to reach RDS on port 5432"
  type        = list(string)
}
variable "db_name" { type = string }
variable "db_username" { type = string }
variable "db_password" {
  type      = string
  sensitive = true
}
variable "instance_class" { type = string }
variable "multi_az" { type = bool }
