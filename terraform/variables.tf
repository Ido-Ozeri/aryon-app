variable "environment" {
  description = "Environment name (e.g., dev, staging, prod)"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.environment))
    error_message = "Environment must be lowercase alphanumeric with hyphens only."
  }
}

variable "region" {
  description = "AWS region to deploy resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z]{2}-[a-z]+-[0-9]$", var.region))
    error_message = "Region must be a valid AWS region format (e.g., us-east-1)."
  }
}

variable "name" {
  description = "Name prefix for all resources"
  type        = string

  validation {
    condition     = can(regex("^[a-z0-9-]+$", var.name)) && length(var.name) <= 32
    error_message = "Name must be lowercase alphanumeric with hyphens, max 32 characters."
  }
}

variable "eks_public_access_cidrs" {
  description = "CIDR blocks allowed to access the EKS public API endpoint"
  type        = list(string)

  validation {
    condition = alltrue([
      for cidr in var.eks_public_access_cidrs : can(cidrnetmask(cidr))
    ])
    error_message = "All elements in eks_public_access_cidrs must be valid IPv4 CIDR notation (e.g., 10.0.0.0/16 or 192.168.1.1/32)."
  }
}
