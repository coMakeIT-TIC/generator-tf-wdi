terraform {
  required_providers {
<%_ if (minikube == "false" || minikube == undefined) { _%>
    aws = {
      source = "hashicorp/aws"
    }
<%_ } _%>
    kubernetes = {
      source  = "hashicorp/kubernetes"
      version = "2.17.0"
    }
  }
}

provider "kubernetes" {
  config_path = "~/.kube/config"
}

<%_ if (minikube == "false" || minikube == undefined) { _%>
provider "aws" {
  region     = var.region
}
<%_ } _%>