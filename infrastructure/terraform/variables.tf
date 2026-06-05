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

variable "mongo_uri" {
  description = "MongoDB Atlas connection string"
  type        = string
  sensitive   = true
}

variable "jwt_secret_key" {
  description = "JWT secret key for backend API"
  type        = string
  sensitive   = true
}
