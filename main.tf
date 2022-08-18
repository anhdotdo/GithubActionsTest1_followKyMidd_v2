# Require TF version to be same as or greater than 0.12.13
terraform {
  required_version = ">=0.12.13"
   backend "s3" {
    bucket         = "s3-anhdo"
    key            = "terraform.tfstate"
    region         = "us-east-1"
    dynamodb_table = "aws-locks"
    encrypt        = true
   }
}

# Download any stable version in AWS provider of 2.36.0 or higher in 2.36 train
provider "aws" {
  region  = "us-east-1"
  #version = "~> 2.36.0"
}

# Call the seed_module to build our ADO seed info
module "bootstrap" {
  source                      = "./modules/bootstrap"
  name_of_s3_bucket           = "s3-anhdo"
  dynamo_db_table_name        = "aws-locks"
}

# ECR 
resource "aws_ecr_repository" "demo-repository" { 
  name                 = "demo-repo" 
  image_tag_mutability = "IMMUTABLE" 
} 
 
resource "aws_ecr_repository_policy" "demo-repo-policy" { 
  repository = aws_ecr_repository.demo-repository.name 
policy = <<EOF
{
  "Version": "2008-10-17", 
  "Statement": [ 
    { 
      "Sid": "adds full ecr access to the demo repository", 
      "Effect": "Allow", 
      "Principal": "*", 
      "Action": [ 
        "ecr:BatchCheckLayerAvailability", 
        "ecr:BatchGetImage", 
        "ecr:CompleteLayerUpload", 
        "ecr:GetDownloadUrlForLayer", 
        "ecr:GetLifecyclePolicy", 
        "ecr:InitiateLayerUpload", 
        "ecr:PutImage", 
        "ecr:UploadLayerPart" 
      ] 
    } 
  ] 
}
EOF
}



