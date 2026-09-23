data "aws_iam_policy_document" "lambda_assume" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["lambda.amazonaws.com"]
    }

    actions = [
      "sts:AssumeRole"
    ]
  }
}

resource "aws_iam_role" "handler" {
  name               = "${local.project}-handler-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "handler_logs" {
  role       = aws_iam_role.handler.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaBasicExecutionRole"
}

resource "aws_iam_role_policy_attachment" "handler_xray" {
  role       = aws_iam_role.handler.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "handler_eventbridge" {
  role = aws_iam_role.handler.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "events:PutEvents"
        ]

        Resource = aws_cloudwatch_event_bus.main.arn
      }
    ]
  })
}

resource "aws_iam_role" "object_worker" {
  name               = "${local.project}-object-worker-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "object_worker_sqs" {
  role       = aws_iam_role.object_worker.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "object_worker_xray" {
  role       = aws_iam_role.object_worker.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "object_worker_s3" {
  role = aws_iam_role.object_worker.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "s3:PutObject"
        ]

        Resource = "${aws_s3_bucket.objects.arn}/*"
      }
    ]
  })
}

# ───────────────  ───────────────


resource "aws_iam_role" "metadata_worker" {
  name               = "${local.project}-metadata-worker-role"
  assume_role_policy = data.aws_iam_policy_document.lambda_assume.json
}

resource "aws_iam_role_policy_attachment" "metadata_worker_sqs" {
  role       = aws_iam_role.metadata_worker.name
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSLambdaSQSQueueExecutionRole"
}

resource "aws_iam_role_policy_attachment" "metadata_worker_xray" {
  role       = aws_iam_role.metadata_worker.name
  policy_arn = "arn:aws:iam::aws:policy/AWSXRayDaemonWriteAccess"
}

resource "aws_iam_role_policy" "metadata_worker_dynamodb" {
  role = aws_iam_role.metadata_worker.id

  policy = jsonencode({
    Version = "2012-10-17"

    Statement = [
      {
        Effect = "Allow"

        Action = [
          "dynamodb:PutItem"
        ]

        Resource = aws_dynamodb_table.metadata.arn
      }
    ]
  })
}

# ───────────────  ───────────────

data "aws_iam_policy_document" "objects_queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.objects.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_cloudwatch_event_rule.objects.arn
      ]
    }
  }
}

resource "aws_sqs_queue_policy" "objects" {
  queue_url = aws_sqs_queue.objects.id
  policy    = data.aws_iam_policy_document.objects_queue.json
}

data "aws_iam_policy_document" "metadata_queue" {
  statement {
    effect = "Allow"

    principals {
      type        = "Service"
      identifiers = ["events.amazonaws.com"]
    }

    actions = [
      "sqs:SendMessage"
    ]

    resources = [
      aws_sqs_queue.metadata.arn
    ]

    condition {
      test     = "ArnEquals"
      variable = "aws:SourceArn"

      values = [
        aws_cloudwatch_event_rule.metadata.arn
      ]
    }
  }
}

resource "aws_sqs_queue_policy" "metadata" {
  queue_url = aws_sqs_queue.metadata.id
  policy    = data.aws_iam_policy_document.metadata_queue.json
}