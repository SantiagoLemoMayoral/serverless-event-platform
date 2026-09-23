data "archive_file" "handler" {
  type        = "zip"
  source_file = "${path.module}/../services/handler/handler.py"
  output_path = "${path.module}/handler.zip"
}

data "archive_file" "object_worker" {
  type        = "zip"
  source_file = "${path.module}/../services/object_worker/handler.py"
  output_path = "${path.module}/object-worker.zip"
}

data "archive_file" "metadata_worker" {
  type        = "zip"
  source_file = "${path.module}/../services/metadata_worker/handler.py"
  output_path = "${path.module}/metadata-worker.zip"
}

resource "aws_lambda_function" "handler" {
  function_name = "${local.project}-handler"

  role    = aws_iam_role.handler.arn
  runtime = "python3.13"
  handler = "handler.lambda_handler"

  filename         = data.archive_file.handler.output_path
  source_code_hash = data.archive_file.handler.output_base64sha256

  timeout = 10

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      EVENT_BUS_NAME = aws_cloudwatch_event_bus.main.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.handler
  ]
}

resource "aws_lambda_function" "object_worker" {
  function_name = "${local.project}-object-worker"

  role    = aws_iam_role.object_worker.arn
  runtime = "python3.13"
  handler = "handler.lambda_handler"

  filename         = data.archive_file.object_worker.output_path
  source_code_hash = data.archive_file.object_worker.output_base64sha256

  timeout = 30

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      BUCKET_NAME = aws_s3_bucket.objects.bucket
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.object_worker
  ]
}

resource "aws_lambda_function" "metadata_worker" {
  function_name = "${local.project}-metadata-worker"

  role    = aws_iam_role.metadata_worker.arn
  runtime = "python3.13"
  handler = "handler.lambda_handler"

  filename         = data.archive_file.metadata_worker.output_path
  source_code_hash = data.archive_file.metadata_worker.output_base64sha256

  timeout = 30

  tracing_config {
    mode = "Active"
  }

  environment {
    variables = {
      TABLE_NAME = aws_dynamodb_table.metadata.name
    }
  }

  depends_on = [
    aws_cloudwatch_log_group.metadata_worker
  ]
}

resource "aws_lambda_event_source_mapping" "objects" {
  event_source_arn = aws_sqs_queue.objects.arn
  function_name    = aws_lambda_function.object_worker.arn

  batch_size = 10

  function_response_types = [
    "ReportBatchItemFailures"
  ]

  depends_on = [
    aws_iam_role_policy_attachment.object_worker_sqs
  ]
}

resource "aws_lambda_event_source_mapping" "metadata" {
  event_source_arn = aws_sqs_queue.metadata.arn
  function_name    = aws_lambda_function.metadata_worker.arn

  batch_size = 10

  function_response_types = [
    "ReportBatchItemFailures"
  ]

  depends_on = [
    aws_iam_role_policy_attachment.metadata_worker_sqs
  ]
}