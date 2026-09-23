output "api_url" {
  value = "${aws_api_gateway_stage.prod.invoke_url}/events"
}

output "bucket" {
  value = aws_s3_bucket.objects.bucket
}

output "dynamodb_table" {
  value = aws_dynamodb_table.metadata.name
}