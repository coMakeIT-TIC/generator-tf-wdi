variable "region" {
  type    = string
  default = [
    <%_ if (cloudProvider == "aws") { _%>
          <%- "\""+awsRegion+"\"" %>
          <%_ } _%>
    <%_ if (cloudProvider == "azure") { _%>
          <%- "\""+location+"\"" %>
          <%_ } _%>
  ]
}

