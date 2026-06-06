locals {
  # Pre-compute ECS names to break cloudwatch <-> ecs circular dependency
  primary_cluster_name   = "${var.project_name}-${var.environment}-primary"
  primary_service_name   = "${var.project_name}-${var.environment}-primary-service"
  secondary_cluster_name = "${var.project_name}-${var.environment}-secondary"
  secondary_service_name = "${var.project_name}-${var.environment}-secondary-service"
}

# ═══════════════════════════════════════════════════════════════════════════════
# PRIMARY REGION — us-east-1
# ═══════════════════════════════════════════════════════════════════════════════

module "vpc_primary" {
  source    = "./modules/vpc"
  providers = { aws = aws.primary }

  project_name        = var.project_name
  environment         = var.environment
  region_label        = "primary"
  vpc_cidr            = var.primary_vpc_cidr
  availability_zones  = var.primary_azs
  public_subnet_cidrs = var.primary_public_subnets
  ecs_subnet_cidrs    = var.primary_ecs_subnets
  rds_subnet_cidrs    = var.primary_rds_subnets
}

module "nat_primary" {
  source    = "./modules/nat_gateway"
  providers = { aws = aws.primary }

  project_name            = var.project_name
  environment             = var.environment
  region_label            = "primary"
  public_subnet_id        = module.vpc_primary.public_subnet_ids[0]
  private_route_table_ids = module.vpc_primary.ecs_route_table_ids
}

module "alb_primary" {
  source    = "./modules/alb"
  providers = { aws = aws.primary }

  project_name      = var.project_name
  environment       = var.environment
  region_label      = "primary"
  vpc_id            = module.vpc_primary.vpc_id
  public_subnet_ids = module.vpc_primary.public_subnet_ids
  container_port    = var.container_port
}

module "ecr_primary" {
  source    = "./modules/ecr"
  providers = { aws = aws.primary }

  project_name = var.project_name
  environment  = var.environment
  region_label = "primary"
}

module "secrets_primary" {
  source    = "./modules/secrets_manager"
  providers = { aws = aws.primary }

  project_name = var.project_name
  environment  = var.environment
  region_label = "primary"
  db_name      = var.db_name
  db_username  = var.db_username
}

module "rds_primary" {
  source    = "./modules/rds"
  providers = { aws = aws.primary }

  project_name     = var.project_name
  environment      = var.environment
  region_label     = "primary"
  vpc_id           = module.vpc_primary.vpc_id
  subnet_ids       = module.vpc_primary.rds_subnet_ids
  ecs_subnet_cidrs = var.primary_ecs_subnets
  db_name          = var.db_name
  db_username      = var.db_username
  db_password      = module.secrets_primary.db_password
  instance_class   = var.db_instance_class
  multi_az         = var.multi_az
}

module "sns_primary" {
  source    = "./modules/sns"
  providers = { aws = aws.primary }

  project_name   = var.project_name
  environment    = var.environment
  region_label   = "primary"
  email_endpoint = var.alert_email
}

module "cloudwatch_primary" {
  source    = "./modules/cloudwatch"
  providers = { aws = aws.primary }

  project_name     = var.project_name
  environment      = var.environment
  region_label     = "primary"
  ecs_cluster_name = local.primary_cluster_name
  ecs_service_name = local.primary_service_name
  sns_topic_arn    = module.sns_primary.topic_arn
  cpu_threshold    = var.cpu_alarm_threshold
}

module "ecs_primary" {
  source    = "./modules/ecs"
  providers = { aws = aws.primary }

  project_name          = var.project_name
  environment           = var.environment
  region_label          = "primary"
  region                = "us-east-1"
  vpc_id                = module.vpc_primary.vpc_id
  subnet_ids            = module.vpc_primary.ecs_subnet_ids
  alb_security_group_id = module.alb_primary.alb_security_group_id
  target_group_arn      = module.alb_primary.target_group_arn
  container_image       = var.primary_container_image
  container_port        = var.container_port
  cpu                   = var.ecs_cpu
  memory                = var.ecs_memory
  desired_count         = var.ecs_desired_count
  db_host               = module.rds_primary.db_address
  db_port               = module.rds_primary.db_port
  db_name               = var.db_name
  db_username           = var.db_username
  secret_arn            = module.secrets_primary.secret_arn
  log_group_name        = module.cloudwatch_primary.log_group_name

  depends_on = [module.nat_primary, module.rds_primary]
}

# ═══════════════════════════════════════════════════════════════════════════════
# SECONDARY REGION — us-west-2
# ═══════════════════════════════════════════════════════════════════════════════

module "vpc_secondary" {
  source    = "./modules/vpc"
  providers = { aws = aws.secondary }

  project_name        = var.project_name
  environment         = var.environment
  region_label        = "secondary"
  vpc_cidr            = var.secondary_vpc_cidr
  availability_zones  = var.secondary_azs
  public_subnet_cidrs = var.secondary_public_subnets
  ecs_subnet_cidrs    = var.secondary_ecs_subnets
  rds_subnet_cidrs    = var.secondary_rds_subnets
}

module "nat_secondary" {
  source    = "./modules/nat_gateway"
  providers = { aws = aws.secondary }

  project_name            = var.project_name
  environment             = var.environment
  region_label            = "secondary"
  public_subnet_id        = module.vpc_secondary.public_subnet_ids[0]
  private_route_table_ids = module.vpc_secondary.ecs_route_table_ids
}

module "alb_secondary" {
  source    = "./modules/alb"
  providers = { aws = aws.secondary }

  project_name      = var.project_name
  environment       = var.environment
  region_label      = "secondary"
  vpc_id            = module.vpc_secondary.vpc_id
  public_subnet_ids = module.vpc_secondary.public_subnet_ids
  container_port    = var.container_port
}

module "ecr_secondary" {
  source    = "./modules/ecr"
  providers = { aws = aws.secondary }

  project_name = var.project_name
  environment  = var.environment
  region_label = "secondary"
}

module "secrets_secondary" {
  source    = "./modules/secrets_manager"
  providers = { aws = aws.secondary }

  project_name = var.project_name
  environment  = var.environment
  region_label = "secondary"
  db_name      = var.db_name
  db_username  = var.db_username
}

module "rds_secondary" {
  source    = "./modules/rds"
  providers = { aws = aws.secondary }

  project_name     = var.project_name
  environment      = var.environment
  region_label     = "secondary"
  vpc_id           = module.vpc_secondary.vpc_id
  subnet_ids       = module.vpc_secondary.rds_subnet_ids
  ecs_subnet_cidrs = var.secondary_ecs_subnets
  db_name          = var.db_name
  db_username      = var.db_username
  db_password      = module.secrets_secondary.db_password
  instance_class   = var.db_instance_class
  multi_az         = var.multi_az
}

module "sns_secondary" {
  source    = "./modules/sns"
  providers = { aws = aws.secondary }

  project_name   = var.project_name
  environment    = var.environment
  region_label   = "secondary"
  email_endpoint = var.alert_email
}

module "cloudwatch_secondary" {
  source    = "./modules/cloudwatch"
  providers = { aws = aws.secondary }

  project_name     = var.project_name
  environment      = var.environment
  region_label     = "secondary"
  ecs_cluster_name = local.secondary_cluster_name
  ecs_service_name = local.secondary_service_name
  sns_topic_arn    = module.sns_secondary.topic_arn
  cpu_threshold    = var.cpu_alarm_threshold
}

module "ecs_secondary" {
  source    = "./modules/ecs"
  providers = { aws = aws.secondary }

  project_name          = var.project_name
  environment           = var.environment
  region_label          = "secondary"
  region                = "us-west-2"
  vpc_id                = module.vpc_secondary.vpc_id
  subnet_ids            = module.vpc_secondary.ecs_subnet_ids
  alb_security_group_id = module.alb_secondary.alb_security_group_id
  target_group_arn      = module.alb_secondary.target_group_arn
  container_image       = var.secondary_container_image
  container_port        = var.container_port
  cpu                   = var.ecs_cpu
  memory                = var.ecs_memory
  desired_count         = var.ecs_desired_count
  db_host               = module.rds_secondary.db_address
  db_port               = module.rds_secondary.db_port
  db_name               = var.db_name
  db_username           = var.db_username
  secret_arn            = module.secrets_secondary.secret_arn
  log_group_name        = module.cloudwatch_secondary.log_group_name

  depends_on = [module.nat_secondary, module.rds_secondary]
}

# ═══════════════════════════════════════════════════════════════════════════════
# S3 FRONTEND — Cross-Region (single module, dual provider)
# ═══════════════════════════════════════════════════════════════════════════════

module "s3_frontend" {
  source = "./modules/s3_frontend"

  providers = {
    aws.primary   = aws.primary
    aws.secondary = aws.secondary
  }

  project_name     = var.project_name
  environment      = var.environment
  primary_region   = "us-east-1"
  secondary_region = "us-west-2"
}
