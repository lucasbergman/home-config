terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    digitalocean = {
      source  = "digitalocean/digitalocean"
      version = "~> 2.0"
    }
    google = {
      source = "hashicorp/google"
    }
    linode = {
      source = "linode/linode"
    }
    local = {
      source = "hashicorp/local"
    }
  }
}

provider "aws" {
  region     = var.aws_region
  access_key = var.aws_access_key_id
  secret_key = var.aws_secret_key
}

provider "digitalocean" {
  token             = var.digitalocean_token
  spaces_access_id  = var.digitalocean_spaces_access_id
  spaces_secret_key = var.digitalocean_spaces_secret_key
}

provider "google" {
  project = var.gcp_project
}

provider "linode" {
  token = var.linode_token
}

terraform {
  backend "gcs" {
    bucket = "bergmans-services-home"
    prefix = "terraform/state"
  }
}
