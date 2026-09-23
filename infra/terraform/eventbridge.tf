resource "aws_cloudwatch_event_bus" "main" {
  name = "${local.project}-bus"
}

resource "aws_cloudwatch_event_rule" "objects" {
  name           = "${local.project}-objects"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source = [
      "serverless.api"
    ]

    detail-type = [
      "object.created"
    ]
  })
}

resource "aws_cloudwatch_event_rule" "metadata" {
  name           = "${local.project}-metadata"
  event_bus_name = aws_cloudwatch_event_bus.main.name

  event_pattern = jsonencode({
    source = [
      "serverless.api"
    ]

    detail-type = [
      "metadata.created"
    ]
  })
}

resource "aws_cloudwatch_event_target" "objects" {
  rule           = aws_cloudwatch_event_rule.objects.name
  event_bus_name = aws_cloudwatch_event_bus.main.name

  target_id = "objects-queue"
  arn       = aws_sqs_queue.objects.arn
}

resource "aws_cloudwatch_event_target" "metadata" {
  rule           = aws_cloudwatch_event_rule.metadata.name
  event_bus_name = aws_cloudwatch_event_bus.main.name

  target_id = "metadata-queue"
  arn       = aws_sqs_queue.metadata.arn
}