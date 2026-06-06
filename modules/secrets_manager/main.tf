resource "random_password" "db" {
  length           = 16
  special          = true
  override_special = "!#%&*()-_=+[]<>:"
}

resource "aws_secretsmanager_secret" "db" {
  name        = "${var.project_name}/${var.environment}/${var.region_label}/db-credentials"
  description = "RDS PostgreSQL credentials for ${var.project_name} ${var.environment}"

  # Allow immediate deletion — important for terraform destroy during testing
  recovery_window_in_days = 0

  tags = {
    Name = "${var.project_name}-${var.environment}-${var.region_label}-db-secret"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id

  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db.result
    dbname   = var.db_name
    port     = 5432
  })
}
