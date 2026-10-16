variable "aws_region" {
  description = "AWS region"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name used for naming resources"
  type        = string
  default     = "tf-demo"
}

variable "tf_state_bucket" {
  description = "S3 bucket name del output TerraformStateBucketName del stack 0_tf-backend"
  type        = string
  default     = "BUCKET_NAME_FROM_CF_OUTPUT"
}
