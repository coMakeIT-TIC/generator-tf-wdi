terraform {
  required_providers {
    aws = {
      source = "hashicorp/aws"
    }
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.17.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

<%_ if (cloudProvider == "aws") { _%>
provider "aws" {
  region     = var.region
}
<%_ } _%>

