terraform {
  backend "s3" {
    bucket         = "muchtodo-month3-terraform-state-275863577386"
    key            = "month3/prod/terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "muchtodo-month3-terraform-locks"
    encrypt        = true
  }
}
