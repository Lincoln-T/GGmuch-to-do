variable "aws_region" {
  description = "AWS region for deployment"
  type        = string
  default     = "us-east-1"
}

variable "project_name" {
  description = "Project name prefix"
  type        = string
  default     = "muchtodo-month3"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "prod"
}

variable "backend_port" {
  description = "Backend API port"
  type        = number
  default     = 8080
}

variable "instance_type" {
  description = "EC2 instance type for backend servers"
  type        = string
  default     = "t3.micro"
}

variable "mongo_uri_parameter_name" {
  description = "SSM Parameter Store name for the MongoDB connection URI"
  type        = string
  default     = "/muchtodo-month3/prod/mongo_uri"
}

variable "jwt_secret_parameter_name" {
  description = "SSM Parameter Store name for the backend JWT secret"
  type        = string
  default     = "/muchtodo-month3/prod/jwt_secret_key"
}

variable "github_owner" {
  description = "GitHub repository owner"
  type        = string
  default     = "Lincoln-T"
}

variable "github_repo" {
  description = "GitHub repository name"
  type        = string
  default     = "GGmuch-to-do"
}

variable "github_branch" {
  description = "GitHub branch allowed to assume the deployment role"
  type        = string
  default     = "month-three-assessment"
}
