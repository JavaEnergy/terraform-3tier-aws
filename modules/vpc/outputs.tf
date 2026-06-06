output "vpc_id" {
  value = aws_vpc.main.id
}

output "public_subnet_ids" {
  value = aws_subnet.public[*].id
}

output "ecs_subnet_ids" {
  value = aws_subnet.ecs[*].id
}

output "rds_subnet_ids" {
  value = aws_subnet.rds[*].id
}

output "ecs_route_table_ids" {
  description = "ECS private route table IDs — NAT module adds the default route here"
  value       = aws_route_table.ecs[*].id
}

output "igw_id" {
  value = aws_internet_gateway.main.id
}
