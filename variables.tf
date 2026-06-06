variable "project_name" {
  description = "Project name used in all resource names"
  type        = string
  default     = "myapp"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "dev"

  validation {
    condition     = contains(["dev", "staging", "prod"], var.environment)
    error_message = "Environment must be dev, staging, or prod."
  }
}

# ─── VPC ────────────────────────────────────────────────────────────────────

variable "primary_vpc_cidr" {
  description = "VPC CIDR for us-east-1"
  type        = string
  default     = "10.0.0.0/16"
}

variable "secondary_vpc_cidr" {
  description = "VPC CIDR for us-west-2"
  type        = string
  default     = "10.1.0.0/16"
}

variable "primary_azs" {
  description = "Availability zones in us-east-1"
  type        = list(string)
  default     = ["us-east-1a", "us-east-1b"]
}

variable "secondary_azs" {
  description = "Availability zones in us-west-2"
  type        = list(string)
  default     = ["us-west-2a", "us-west-2b"]
}

variable "primary_public_subnets" {
  description = "Public subnet CIDRs in us-east-1 (for ALB)"
  type        = list(string)
  default     = ["10.0.1.0/24", "10.0.2.0/24"]
}

variable "primary_ecs_subnets" {
  description = "Private subnet CIDRs in us-east-1 (for ECS)"
  type        = list(string)
  default     = ["10.0.10.0/24", "10.0.11.0/24"]
}

variable "primary_rds_subnets" {
  description = "Private subnet CIDRs in us-east-1 (for RDS)"
  type        = list(string)
  default     = ["10.0.20.0/24", "10.0.21.0/24"]
}

variable "secondary_public_subnets" {
  description = "Public subnet CIDRs in us-west-2 (for ALB)"
  type        = list(string)
  default     = ["10.1.1.0/24", "10.1.2.0/24"]
}

variable "secondary_ecs_subnets" {
  description = "Private subnet CIDRs in us-west-2 (for ECS)"
  type        = list(string)
  default     = ["10.1.10.0/24", "10.1.11.0/24"]
}

variable "secondary_rds_subnets" {
  description = "Private subnet CIDRs in us-west-2 (for RDS)"
  type        = list(string)
  default     = ["10.1.20.0/24", "10.1.21.0/24"]
}

# ─── DATABASE ───────────────────────────────────────────────────────────────

variable "db_name" {
  description = "PostgreSQL database name"
  type        = string
  default     = "appdb"
}

variable "db_username" {
  description = "PostgreSQL master username"
  type        = string
  default     = "appuser"
}

variable "db_instance_class" {
  description = "RDS instance class"
  type        = string
  default     = "db.t3.micro"
}

variable "multi_az" {
  description = "Enable Multi-AZ for RDS (true for prod, false for dev)"
  type        = bool
  default     = false
}

# ─── ECS ────────────────────────────────────────────────────────────────────

variable "ecs_cpu" {
  description = "Fargate task CPU units"
  type        = number
  default     = 256
}

variable "ecs_memory" {
  description = "Fargate task memory in MB"
  type        = number
  default     = 512
}

variable "ecs_desired_count" {
  description = "Number of ECS tasks per region"
  type        = number
  default     = 1
}

variable "container_port" {
  description = "Port the Flask app listens on"
  type        = number
  default     = 5000
}

variable "primary_container_image" {
  description = "Docker image URL for primary region (ECR). Update after first push."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:latest"
}

variable "secondary_container_image" {
  description = "Docker image URL for secondary region (ECR). Update after first push."
  type        = string
  default     = "public.ecr.aws/nginx/nginx:latest"
}

# ─── MONITORING ─────────────────────────────────────────────────────────────

variable "alert_email" {
  description = "Email address for SNS CPU alerts"
  type        = string
  default     = "chogovadzebeka@gmail.com"
}

variable "cpu_alarm_threshold" {
  description = "ECS CPU % threshold that triggers SNS alarm"
  type        = number
  default     = 80
}
