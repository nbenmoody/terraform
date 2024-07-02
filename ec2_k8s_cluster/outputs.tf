output "cluster_nodes" {
  value = [for instance in aws_instance.cluster_nodes: instance.public_ip]
}

output "admin_node" {
  value = aws_instance.admin_node.public_ip
}