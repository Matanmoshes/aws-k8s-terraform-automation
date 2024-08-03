terraform {
  backend "s3" {
    bucket         = "k8sproject-infrastructure-4545kljdgklfdjgk4j54kjl"
    key            = "path/to/your/terraform.tfstate"
    region         = "us-east-1"
    encrypt        = true
    dynamodb_table = "<your-dynamodb-table>"
  }
}
