resource "aws_ecr_repository" "lambda" {
  name = "serverless-event-platform"

  image_scanning_configuration {
    scan_on_push = true
  }
}