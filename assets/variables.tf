variable "gcp_project" {
  description = "GCP project name"
  type        = string
  default     = "bergmans-services"
}

variable "linode_token" {
  description = "Linode API token"
  type        = string
}

variable "linode_region" {
  description = "Region to place instances; see https://api.linode.com/v4/regions"
  type        = string
  default     = "us-central"
}

variable "linode_type" {
  description = "Instance type; see https://api.linode.com/v4/linode/types"
  type        = string
  default     = "g6-standard-2"
}
