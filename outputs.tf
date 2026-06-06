# ─── PRIMARY REGION (us-east-1) ─────────────────────────────────────────────

output "primary_alb_dns" {
  description = "ALB DNS name for the primary region backend"
  value       = module.alb_primary.alb_dns_name
}

output "primary_ecr_url" {
  description = "ECR repository URL for primary region"
  value       = module.ecr_primary.repository_url
}

output "primary_rds_endpoint" {
  description = "RDS endpoint for primary region"
  value       = module.rds_primary.db_endpoint
  sensitive   = true
}

output "primary_ecs_cluster" {
  description = "ECS cluster name in primary region"
  value       = module.ecs_primary.cluster_name
}

# ─── SECONDARY REGION (us-west-2) ────────────────────────────────────────────

output "secondary_alb_dns" {
  description = "ALB DNS name for the secondary region backend"
  value       = module.alb_secondary.alb_dns_name
}

output "secondary_ecr_url" {
  description = "ECR repository URL for secondary region"
  value       = module.ecr_secondary.repository_url
}

output "secondary_rds_endpoint" {
  description = "RDS endpoint for secondary region"
  value       = module.rds_secondary.db_endpoint
  sensitive   = true
}

output "secondary_ecs_cluster" {
  description = "ECS cluster name in secondary region"
  value       = module.ecs_secondary.cluster_name
}

# ─── S3 FRONTEND ─────────────────────────────────────────────────────────────

output "s3_primary_website" {
  description = "S3 static website URL (primary, us-east-1)"
  value       = module.s3_frontend.primary_website_endpoint
}

output "s3_secondary_website" {
  description = "S3 static website URL (replica, us-west-2)"
  value       = module.s3_frontend.secondary_website_endpoint
}

output "s3_primary_bucket" {
  description = "S3 source bucket name"
  value       = module.s3_frontend.primary_bucket_name
}

# ─── NEXT STEPS ─────────────────────────────────────────────────────────────

output "next_steps" {
  description = "What to do after apply"
  value       = <<-EOT
    1. Check your email (${var.alert_email}) and CONFIRM the SNS subscription.
    2. Build & push Flask image:
         cd app
         ./build_and_push.sh ${module.ecr_primary.repository_url} ${module.ecr_secondary.repository_url}
    3. Update terraform.tfvars with ECR image URLs, then run: terraform apply
    4. Test the backend:
         curl http://${module.alb_primary.alb_dns_name}/
         curl http://${module.alb_primary.alb_dns_name}/health
    5. Upload index.html to S3: aws s3 cp index.html s3://${module.s3_frontend.primary_bucket_name}/
    6. Destroy when done: terraform destroy -auto-approve
  EOT
}
