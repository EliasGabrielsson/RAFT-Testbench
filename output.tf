output "etcd-bootstrap-node-public_ip" {
  value = aws_eip.etcd-bootstrap-node-public_ip.public_ip
  description = "The public IP address of the etcd bootstrap node used to access the cluster"
}

output "etcd-bootstrap-node-private_ip" {
  value = aws_instance.etcd-bootstrap-node.private_ip
  description = "The private IP address (cloud network) of the etcd bootstrap node in the cluster"
}

output "etcd-node-private_ip" {
  value = aws_instance.etcd-node.*.private_ip
  description = "The private IP address (cloud network) of etcd nodes in the cluster"
}

# output "Ignite-config" {
#   value = data.ignition_config.etcd3.rendered
#   description = "The ignite configuration provided to each core os node."
# }