resource "kubectl_manifest" "elasticsearch" {
  yaml_body = <<YAML
      apiVersion: elasticsearch.k8s.elastic.co/v1
      kind: Elasticsearch
      metadata:
        name: quickstart
      spec:
        version: 8.7.0
        nodeSets:
        - name: default
          count: 1
          config:
            node.store.allow_mmap: false
          <%_ if (onCloud) { _%> 
          podTemplate:
            spec:
              affinity:
                nodeAffinity:
                  requiredDuringSchedulingIgnoredDuringExecution:
                    nodeSelectorTerms:
                    - matchExpressions:
                      <%_ if (cloudProvider == "aws") { _%>
                      - key: eks.amazonaws.com/nodegroup
                        operator: In
                        values:
                        - ${var.cluster_name}-eck-node-group
                      <%_ } _%>
                      <%_ if (cloudProvider == "azure") { _%>
                      - key: agentpool
                        operator: In
                        values:
                        - ${var.eck_node_pool}
                      <%_ } _%>
          <%_ } _%>
  YAML

  depends_on = [
    kubectl_manifest.operator
  ]
}

resource "kubectl_manifest" "elasticsearch_lb" {
  yaml_body = <<YAML
      apiVersion: v1
      kind: Service
      metadata:
        name: elasticsearch-nlb
        <%_ if (onCloud) { _%> 
        annotations:
          <%_ if (cloudProvider == "aws") { _%>
          service.beta.kubernetes.io/aws-load-balancer-type: external 
          service.beta.kubernetes.io/aws-load-balancer-scheme: internet-facing
          service.beta.kubernetes.io/aws-load-balancer-nlb-target-type: instance
          <%_ } _%>
          <%_ if (cloudProvider == "azure") { _%>
          service.beta.kubernetes.io/azure-dns-label-name: elasticsearch
          <%_ } _%>
        <%_ } _%>
        namespace: default
      spec:
        type: <%= !onCloud ? 'NodePort' : 'LoadBalancer' %>
        ports:
          - port: 9200
            targetPort: 9200
        <%_ if (!onCloud) { _%>
            nodePort: 30300
        <%_ } _%>
            name: http
        selector:
          common.k8s.elastic.co/type: elasticsearch
          elasticsearch.k8s.elastic.co/cluster-name: quickstart
  YAML

  depends_on = [
    kubectl_manifest.elasticsearch
  ]
}

<%_ if (onCloud) { _%>
resource "null_resource" "print_elasticsearch_loadBalancer_dns" {
  provisioner "local-exec" {
    command = <<-EOT
      dns=$(kubectl get service elasticsearch-nlb -o jsonpath='{.status.loadBalancer.ingress[0].hostname}')
      echo "https://${dns}:9200" >> elasticsearch-dns.txt
    EOT

    interpreter = ["bash", "-c"]
  }

  depends_on = [
    kubectl_manifest.elasticsearch_lb
  ]
}
<%_ } _%>
