variable "raphaeliac_vpc_id" {
  type        = string
  description = "id of the vpc"
  default     = ""
}

variable "debian_ami" {
  type        = string
  description = "AMI ID of our linux instances"
  default     = "ami-087da76081e7685da"
}

variable "worker_nodes_count" {
  type        = number
  description = "total number of worker nodes"
  default     = 2
}

variable "EIP" {
  type        = string
  description = "our eip"
  default     = ""
}

variable "AWS_ACCESS_KEY_ID" {
  type        = string
  description = "Our AWS Access Key ID"
  default     = ""
}

variable "AWS_SECRET_ACCESS_KEY" {
  type        = string
  description = "Our AWS Secret Access Key"
  default     = ""
}

variable "S3_REGION" {
  type        = string
  description = "Our region"
  default     = ""
}

variable "S3_BUCKET" {
  type        = string
  description = "Our bucket name"
  default     = ""
}

variable "REGISTRY_FRONTEND" {
  type        = string
  description = "Link to Where our Docker frontend image is stored"
  default     = "registry.gitlab.com/projets-persos4/iac/frontend"
}

variable "REGISTRY_BACKEND" {
  type        = string
  description = "Link to Where our Docker backend image is stored"
  default     = "registry.gitlab.com/projets-persos4/iac/frontend"
}
