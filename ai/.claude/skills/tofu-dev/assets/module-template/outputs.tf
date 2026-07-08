output "bucket_id" {
  description = "Name of the example S3 bucket."
  value       = aws_s3_bucket.this.id
}

output "bucket_arn" {
  description = "ARN of the example S3 bucket."
  value       = aws_s3_bucket.this.arn
}
