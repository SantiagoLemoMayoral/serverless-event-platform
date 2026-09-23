resource "aws_api_gateway_rest_api" "api" {
  name = local.project
}

resource "aws_api_gateway_resource" "events" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  parent_id   = aws_api_gateway_rest_api.api.root_resource_id

  path_part = "events"
}

resource "aws_api_gateway_method" "post" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.events.id

  http_method   = "POST"
  authorization = "NONE"
}

resource "aws_api_gateway_integration" "handler" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  resource_id = aws_api_gateway_resource.events.id
  http_method = aws_api_gateway_method.post.http_method

  integration_http_method = "POST"
  type                    = "AWS_PROXY"

  uri = aws_lambda_function.handler.invoke_arn
}

resource "aws_lambda_permission" "api_gateway" {
  statement_id = "AllowAPIGateway"

  action        = "lambda:InvokeFunction"
  function_name = aws_lambda_function.handler.function_name

  principal = "apigateway.amazonaws.com"

  source_arn = "${aws_api_gateway_rest_api.api.execution_arn}/*/*"
}

resource "aws_api_gateway_deployment" "api" {
  rest_api_id = aws_api_gateway_rest_api.api.id

  triggers = {
    redeployment = sha1(jsonencode([
      aws_api_gateway_resource.events.id,
      aws_api_gateway_method.post.id,
      aws_api_gateway_integration.handler.id
    ]))
  }

  lifecycle {
    create_before_destroy = true
  }
}

resource "aws_api_gateway_stage" "prod" {
  deployment_id = aws_api_gateway_deployment.api.id
  rest_api_id   = aws_api_gateway_rest_api.api.id

  stage_name = "prod"

  xray_tracing_enabled = true

  access_log_settings {
    destination_arn = aws_cloudwatch_log_group.api_gateway.arn

    format = jsonencode({
      requestId   = "$context.requestId"
      requestTime = "$context.requestTime"
      status      = "$context.status"
      path        = "$context.path"
    })
  }

  depends_on = [
    aws_api_gateway_account.main
  ]
}

resource "aws_api_gateway_method_settings" "all" {
  rest_api_id = aws_api_gateway_rest_api.api.id
  stage_name  = aws_api_gateway_stage.prod.stage_name

  method_path = "*/*"

  settings {
    metrics_enabled = true
    logging_level   = "INFO"
  }
}

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