terraform {
  required_providers {
    aws = {
      source                = "hashicorp/aws"
      configuration_aliases = [aws.primary, aws.secondary]
    }
  }
}

locals {
  primary_bucket_name   = "${var.project_name}-${var.environment}-frontend-primary"
  secondary_bucket_name = "${var.project_name}-${var.environment}-frontend-replica"
}

# ─── DATA: current AWS account ID ────────────────────────────────────────────

data "aws_caller_identity" "primary" {
  provider = aws.primary
}

# ─── PRIMARY BUCKET (us-east-1) ─ Source for CRR ─────────────────────────────

resource "aws_s3_bucket" "primary" {
  provider = aws.primary
  bucket   = "${local.primary_bucket_name}-${data.aws_caller_identity.primary.account_id}"

  tags = {
    Name = local.primary_bucket_name
    Role = "frontend-source"
  }
}

resource "aws_s3_bucket_versioning" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  index_document { suffix = "index.html" }
  error_document { key = "error.html" }
}

resource "aws_s3_bucket_public_access_block" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "primary" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.primary.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.primary]
}

# ─── REPLICA BUCKET (us-west-2) ─ Target for CRR ─────────────────────────────

resource "aws_s3_bucket" "replica" {
  provider = aws.secondary
  bucket   = "${local.secondary_bucket_name}-${data.aws_caller_identity.primary.account_id}"

  tags = {
    Name = local.secondary_bucket_name
    Role = "frontend-replica"
  }
}

resource "aws_s3_bucket_versioning" "replica" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.replica.id

  versioning_configuration {
    status = "Enabled"
  }
}

resource "aws_s3_bucket_website_configuration" "replica" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.replica.id

  index_document { suffix = "index.html" }
  error_document { key = "error.html" }
}

resource "aws_s3_bucket_public_access_block" "replica" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.replica.id

  block_public_acls       = false
  block_public_policy     = false
  ignore_public_acls      = false
  restrict_public_buckets = false
}

resource "aws_s3_bucket_policy" "replica" {
  provider = aws.secondary
  bucket   = aws_s3_bucket.replica.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Sid       = "PublicReadGetObject"
      Effect    = "Allow"
      Principal = "*"
      Action    = "s3:GetObject"
      Resource  = "${aws_s3_bucket.replica.arn}/*"
    }]
  })

  depends_on = [aws_s3_bucket_public_access_block.replica]
}

# ─── IAM ROLE FOR REPLICATION ─────────────────────────────────────────────────

resource "aws_iam_role" "replication" {
  provider = aws.primary
  name     = "${var.project_name}-${var.environment}-s3-replication-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [{
      Action    = "sts:AssumeRole"
      Effect    = "Allow"
      Principal = { Service = "s3.amazonaws.com" }
    }]
  })
}

resource "aws_iam_role_policy" "replication" {
  provider = aws.primary
  name     = "${var.project_name}-${var.environment}-s3-replication-policy"
  role     = aws_iam_role.replication.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "s3:GetReplicationConfiguration",
          "s3:ListBucket"
        ]
        Resource = [aws_s3_bucket.primary.arn]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:GetObjectVersionForReplication",
          "s3:GetObjectVersionAcl",
          "s3:GetObjectVersionTagging"
        ]
        Resource = ["${aws_s3_bucket.primary.arn}/*"]
      },
      {
        Effect = "Allow"
        Action = [
          "s3:ReplicateObject",
          "s3:ReplicateDelete",
          "s3:ReplicateTags"
        ]
        Resource = ["${aws_s3_bucket.replica.arn}/*"]
      }
    ]
  })
}

# ─── CROSS-REGION REPLICATION CONFIGURATION ──────────────────────────────────

resource "aws_s3_bucket_replication_configuration" "crr" {
  provider = aws.primary
  bucket   = aws_s3_bucket.primary.id
  role     = aws_iam_role.replication.arn

  rule {
    id     = "replicate-all"
    status = "Enabled"

    destination {
      bucket        = aws_s3_bucket.replica.arn
      storage_class = "STANDARD"
    }
  }

  depends_on = [
    aws_s3_bucket_versioning.primary,
    aws_s3_bucket_versioning.replica
  ]
}
