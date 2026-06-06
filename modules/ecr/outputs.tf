output "repository_url" {
  value = aws_ecr_repository.app.repository_url
}

output "registry_id" {
  value = aws_ecr_repository.app.registry_id
}

output "repository_name" {
  value = aws_ecr_repository.app.name
}
