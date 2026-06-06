locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.region_label}"
}

resource "aws_eip" "nat" {
  domain = "vpc"

  tags = {
    Name = "${local.name_prefix}-nat-eip"
  }
}

resource "aws_nat_gateway" "main" {
  allocation_id = aws_eip.nat.id
  subnet_id     = var.public_subnet_id

  tags = {
    Name = "${local.name_prefix}-nat"
  }

  depends_on = [aws_eip.nat]
}

# Add default route to each ECS private route table
resource "aws_route" "ecs_nat" {
  count = length(var.private_route_table_ids)

  route_table_id         = var.private_route_table_ids[count.index]
  destination_cidr_block = "0.0.0.0/0"
  nat_gateway_id         = aws_nat_gateway.main.id
}
