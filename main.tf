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

resource "aws_ecs_cluster" "demo-ecs-cluster" { 
  name = "ecs-cluster-for-demo" 
} 
 
resource "aws_ecs_service" "demo-ecs-service-two" { 
  name            = "demo-app" 
  cluster         = aws_ecs_cluster.demo-ecs-cluster.id 
  task_definition = aws_ecs_task_definition.demo-ecs-task-definition.arn 
  launch_type     = "FARGATE" 
  network_configuration { 
    subnets          = ["subnet-00266a905d7a5c90c"] 
    assign_public_ip = true 
  } 
  desired_count = 1 
} 
 
resource "aws_ecs_task_definition" "demo-ecs-task-definition" { 
  family                   = "ecs-task-definition-demo" 
  network_mode             = "awsvpc" 
  requires_compatibilities = ["FARGATE"] 
  memory                   = "1024" 
  cpu                      = "512" 
  execution_role_arn       = "arn:aws:iam::335856564507:role/aws-service-role/ecs.amazonaws.com/AWSServiceRoleForECS" 
  container_definitions    = <<EOF
  [
    { 
      "name": "demo-container", 
      "image": "335856564507.dkr.ecr.us-east-1.amazonaws.com/demo-repo:5ce176634bce1a437376815d5d222b07bac867e9", 
      "memory": 1024, 
      "cpu": 512, 
      "essential": true, 
      "entryPoint": ["/"], 
      "portMappings": [ 
        { 
          "containerPort": 80, 
          "hostPort": 80
        } 
      ] 
    } 
  ]
  EOF
} 


