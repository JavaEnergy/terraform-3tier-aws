locals {
  name_prefix = "${var.project_name}-${var.environment}-${var.region_label}"
}

# ─── VPC ────────────────────────────────────────────────────────────────────

resource "aws_vpc" "main" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true

  tags = {
    Name = "${local.name_prefix}-vpc"
  }
}

# ─── INTERNET GATEWAY ────────────────────────────────────────────────────────

resource "aws_internet_gateway" "main" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-igw"
  }
}

# ─── PUBLIC SUBNETS (ALB) ────────────────────────────────────────────────────

resource "aws_subnet" "public" {
  count = length(var.public_subnet_cidrs)

  vpc_id                  = aws_vpc.main.id
  cidr_block              = var.public_subnet_cidrs[count.index]
  availability_zone       = var.availability_zones[count.index]
  map_public_ip_on_launch = true

  tags = {
    Name = "${local.name_prefix}-public-${count.index + 1}"
    Tier = "public"
  }
}

# ─── PRIVATE ECS SUBNETS (ECS Fargate) ───────────────────────────────────────

resource "aws_subnet" "ecs" {
  count = length(var.ecs_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.ecs_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-ecs-${count.index + 1}"
    Tier = "private-ecs"
  }
}

# ─── PRIVATE RDS SUBNETS ─────────────────────────────────────────────────────

resource "aws_subnet" "rds" {
  count = length(var.rds_subnet_cidrs)

  vpc_id            = aws_vpc.main.id
  cidr_block        = var.rds_subnet_cidrs[count.index]
  availability_zone = var.availability_zones[count.index]

  tags = {
    Name = "${local.name_prefix}-rds-${count.index + 1}"
    Tier = "private-rds"
  }
}

# ─── PUBLIC ROUTE TABLE ───────────────────────────────────────────────────────

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.main.id
  }

  tags = {
    Name = "${local.name_prefix}-rt-public"
  }
}

resource "aws_route_table_association" "public" {
  count = length(aws_subnet.public)

  subnet_id      = aws_subnet.public[count.index].id
  route_table_id = aws_route_table.public.id
}

# ─── PRIVATE ECS ROUTE TABLES (NAT routes added by nat_gateway module) ───────

resource "aws_route_table" "ecs" {
  count = length(var.ecs_subnet_cidrs)

  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rt-ecs-${count.index + 1}"
  }
}

resource "aws_route_table_association" "ecs" {
  count = length(aws_subnet.ecs)

  subnet_id      = aws_subnet.ecs[count.index].id
  route_table_id = aws_route_table.ecs[count.index].id
}

# ─── PRIVATE RDS ROUTE TABLE (no internet access) ────────────────────────────

resource "aws_route_table" "rds" {
  vpc_id = aws_vpc.main.id

  tags = {
    Name = "${local.name_prefix}-rt-rds"
  }
}

resource "aws_route_table_association" "rds" {
  count = length(aws_subnet.rds)

  subnet_id      = aws_subnet.rds[count.index].id
  route_table_id = aws_route_table.rds.id
}
