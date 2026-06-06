variable "project_name" { type = string }
variable "environment" { type = string }
variable "region_label" { type = string }

variable "public_subnet_id" {
  description = "Public subnet ID to place the NAT Gateway in"
  type        = string
}

variable "private_route_table_ids" {
  description = "ECS private route table IDs to add the NAT default route to"
  type        = list(string)
}
