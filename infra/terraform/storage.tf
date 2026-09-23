resource "aws_s3_bucket" "objects" {
  bucket = "${local.project}-${data.aws_caller_identity.current.account_id}-objects"
}

resource "aws_dynamodb_table" "metadata" {
  name         = "${local.project}-metadata"
  billing_mode = "PAY_PER_REQUEST"

  hash_key = "id"

  attribute {
    name = "id"
    type = "S"
  }
}