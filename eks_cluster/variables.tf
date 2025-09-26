variable "region" {
  description = "AWS region"
  type        = string
  default     = "us-west-2"
}

variable "vpc_id" {
  description = "VPC ID where EKS will be created"
  type        = string
}

variable "node_ami_type" {
  description = "Type of Amazon Machine Image (AMI) associated with the EKS Node Group. Valid values: AL2_x86_64, AL2_ARM_64, AL2_x86_64_GPU, BOTTLEROCKET_x86_64, BOTTLEROCKET_ARM_64, WINDOWS_CORE_2019_x86_64, WINDOWS_FULL_2019_x86_64"
  type        = string
  default     = "AL2_x86_64"
}

variable "cluster_subnet_ids" {
  description = "List of subnet IDs where EKS cluster control plane ENIs will be created (typically private and/or public subnets)"
  type        = list(string)
}

variable "node_group_subnet_ids" {
  description = "List of subnet IDs where EKS worker nodes will be launched (typically private subnets)"
  type        = list(string)
}

variable "cluster_name" {
  description = "EKS Cluster name"
  type        = string
}

variable "node_instance_types" {
  description = "List of instance types for the EKS node group"
  type        = list(string)
  default     = ["t3.medium"]
}

variable "node_desired_size" {
  description = "Desired number of worker nodes"
  type        = number
  default     = 2
}

variable "node_max_size" {
  description = "Maximum number of worker nodes"
  type        = number
  default     = 3
}

variable "node_min_size" {
  description = "Minimum number of worker nodes"
  type        = number
  default     = 1
}

variable "node_disk_size" {
  description = "Disk size in GiB for worker nodes"
  type        = number
  default     = 50
}

variable "cluster_version" {
  description = "Kubernetes version to use for the EKS cluster"
  type        = string
  default     = "1.27"
}

variable "endpoint_private_access" {
  description = "Whether the EKS private API server endpoint is enabled"
  type        = bool
  default     = false
}

variable "endpoint_public_access" {
  description = "Whether the EKS public API server endpoint is enabled"
  type        = bool
  default     = true
}

variable "tags" {
  description = "A map of tags to add to all resources"
  type        = map(string)
  default     = {}
}

variable "existing_cluster_role_arn" {
  description = "ARN of existing IAM role for EKS cluster"
  type        = string
  default     = ""
}

variable "existing_node_role_arn" {
  description = "ARN of existing IAM role for EKS node group"
  type        = string
  default     = ""
}

variable "node_readiness_wait_duration" {
  description = "Duration to wait for nodes to be ready before deploying addons (e.g., '2m', '5m')"
  type        = string
  default     = "1m"
}

# c7g.xlarge Node Group Variables
variable "node_desired_size_m7i_flex" {
  description = "Desired number of t3.micro worker nodes"
  type        = number
  default     = 1
}

variable "node_max_size_m7i_flex" {
  description = "Maximum number of t3.micro worker nodes"
  type        = number
  default     = 2
}

variable "node_min_size_m7i_flex" {
  description = "Minimum number of t3.micro worker nodes"
  type        = number
  default     = 1
}

variable "node_disk_size_m7i_flex" {
  description = "Disk size in GiB for t3.micro worker nodes"
  type        = number
  default     = 50
}

# IRSA Configuration
variable "enable_irsa" {
  description = "Enable IAM Roles for Service Accounts (IRSA)"
  type        = bool
  default     = true
}

variable "enable_ebs_csi_driver_irsa" {
  description = "Enable EBS CSI Driver IRSA role"
  type        = bool
  default     = false
}

# Existing IRSA Role ARNs
variable "existing_ebs_csi_role_arn" {
  description = "ARN of existing IAM role for EBS CSI driver"
  type        = string
  default     = ""
}