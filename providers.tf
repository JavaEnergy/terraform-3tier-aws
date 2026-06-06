terraform {
  required_version = ">= 1.5.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    random = {
      source  = "hashicorp/random"
      version = "~> 3.6"
    }
  }
}

provider "aws" {
  alias  = "primary"
  region = "us-east-1"

  default_tags {
    tags = {
      Project     = "terraform-3tier"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}

provider "aws" {
  alias  = "secondary"
  region = "us-west-2"

  default_tags {
    tags = {
      Project     = "terraform-3tier"
      Environment = "dev"
      ManagedBy   = "Terraform"
    }
  }
}
