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
