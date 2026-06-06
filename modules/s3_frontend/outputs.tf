output "primary_bucket_name" {
  value = aws_s3_bucket.primary.id
}

output "secondary_bucket_name" {
  value = aws_s3_bucket.replica.id
}

output "primary_website_endpoint" {
  value = aws_s3_bucket_website_configuration.primary.website_endpoint
}

output "secondary_website_endpoint" {
  value = aws_s3_bucket_website_configuration.replica.website_endpoint
}

output "primary_bucket_arn" {
  value = aws_s3_bucket.primary.arn
}

output "secondary_bucket_arn" {
  value = aws_s3_bucket.replica.arn
}
