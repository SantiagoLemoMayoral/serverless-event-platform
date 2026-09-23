resource "aws_cloudwatch_log_group" "handler" {
  name              = "/aws/lambda/${local.project}-handler"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "object_worker" {
  name              = "/aws/lambda/${local.project}-object-worker"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "metadata_worker" {
  name              = "/aws/lambda/${local.project}-metadata-worker"
  retention_in_days = 14
}

resource "aws_cloudwatch_log_group" "api_gateway" {
  name              = "/aws/api-gateway/${local.project}"
  retention_in_days = 14
}

resource "aws_iam_role" "api_gateway_cloudwatch" {
  name = "${local.project}-api-gateway-cloudwatch"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Principal = {
          Service = "apigateway.amazonaws.com"
        }

        Action = "sts:AssumeRole"
      }
    ]
  })
}

resource "aws_iam_role_policy_attachment" "api_gateway_cloudwatch" {
  role = aws_iam_role.api_gateway_cloudwatch.name

  policy_arn = "arn:aws:iam::aws:policy/service-role/AmazonAPIGatewayPushToCloudWatchLogs"
}

resource "aws_api_gateway_account" "main" {
  cloudwatch_role_arn = aws_iam_role.api_gateway_cloudwatch.arn
}

resource "aws_cloudwatch_metric_alarm" "objects_dlq" {
  alarm_name = "${local.project}-objects-dlq-not-empty"

  namespace   = "AWS/SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"

  statistic = "Maximum"
  period    = 60

  evaluation_periods = 1

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1

  dimensions = {
    QueueName = aws_sqs_queue.objects_dlq.name
  }
}


resource "aws_cloudwatch_metric_alarm" "metadata_dlq" {
  alarm_name = "${local.project}-metadata-dlq-not-empty"

  namespace   = "AWS/SQS"
  metric_name = "ApproximateNumberOfMessagesVisible"

  statistic = "Maximum"
  period    = 60

  evaluation_periods = 1

  comparison_operator = "GreaterThanOrEqualToThreshold"
  threshold           = 1

  dimensions = {
    QueueName = aws_sqs_queue.metadata_dlq.name
  }
}