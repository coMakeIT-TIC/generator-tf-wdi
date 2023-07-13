<%_ if (onCloud) { _%>
terraform {
 required_providers {
<%_ if (cloudProvider == "aws") { _%>
    aws = {
    source = "hashicorp/aws"
    }
<%_ } _%>
<%_ if (cloudProvider == "azure") { _%>
   azurerm = {
      source = "hashicorp/azurerm"
      version = "=3.0.0"
    }
<%_ } _%>
 }
}
<%_ } _%>

provider "kubernetes" {
  config_path = "~/.kube/config"
}