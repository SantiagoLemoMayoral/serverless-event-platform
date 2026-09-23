terraform {
  backend "s3" {
    bucket       = "serverless-event-platform-tfstate"
    key          = "dev/terraform.tfstate"
    region       = "us-east-1"
    encrypt      = true
    use_lockfile = true
  }
}