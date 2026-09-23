terraform {
  required_version = ">= 1.8.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }

    archive = {
      source  = "hashicorp/archive"
      version = "~> 2.0"
    }
  }
}

provider "aws" {
  region = "us-east-1"
}

data "aws_caller_identity" "current" {}

locals {
  project = "serverless-event-platform"
}

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

