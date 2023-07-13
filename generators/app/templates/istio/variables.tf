<%_ if (onCloud) { _%>
variable "cluster_name" {
  type    = string
  default = <%- "\""+clusterName+"\"" %>
}
<%_ } _%>