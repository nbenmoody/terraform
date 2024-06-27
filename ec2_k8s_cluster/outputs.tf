output "aws_instances" {
  value = [for instance in aws_instance.cluster_nodes: instance.public_ip]
}