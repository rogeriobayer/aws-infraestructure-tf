terraform {
  required_version = ">= 1.0"
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = var.aws_region
}

terraform {
  backend "s3" {  
    bucket         = "rogerio-terraform-state-bucket" 
    key            = "terraform.tfstate"                    
    region         = "us-east-2"                            
    encrypt        = true                                  
  }
}

