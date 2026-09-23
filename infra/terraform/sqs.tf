resource "aws_sqs_queue" "objects" {
  name                       = "${local.project}-objects"
  visibility_timeout_seconds = 60
}

resource "aws_sqs_queue" "objects_dlq" {
  name = "${local.project}-objects-dlq"
}

resource "aws_sqs_queue" "metadata" {
  name                       = "${local.project}-metadata"
  visibility_timeout_seconds = 60
}

resource "aws_sqs_queue" "metadata_dlq" {
  name = "${local.project}-metadata-dlq"
}

#------------------------------------------------------------------

resource "aws_sqs_queue_redrive_policy" "objects" {
  queue_url = aws_sqs_queue.objects.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.objects_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_redrive_policy" "metadata" {
  queue_url = aws_sqs_queue.metadata.id

  redrive_policy = jsonencode({
    deadLetterTargetArn = aws_sqs_queue.metadata_dlq.arn
    maxReceiveCount     = 5
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "objects_dlq" {
  queue_url = aws_sqs_queue.objects_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.objects.arn]
  })
}

resource "aws_sqs_queue_redrive_allow_policy" "metadata_dlq" {
  queue_url = aws_sqs_queue.metadata_dlq.id

  redrive_allow_policy = jsonencode({
    redrivePermission = "byQueue"
    sourceQueueArns   = [aws_sqs_queue.metadata.arn]
  })
}

