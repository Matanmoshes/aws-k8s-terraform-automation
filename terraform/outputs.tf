# outputs.tf

output "bastion_public_ip" {
  description = "Public IP address of the bastion host"
  value       = aws_eip.bastion_eip.public_ip
}

output "ansible_control_private_ip" {
  description = "Private IP address of the Ansible control machine"
  value       = aws_instance.ansible_control.private_ip
}

output "control_plane_private_ip" {
  description = "Private IP address of the Kubernetes control plane node"
  value       = aws_instance.control_plane.private_ip
}

output "worker_nodes_private_ips" {
  description = "Private IP addresses of the Kubernetes worker nodes"
  value       = [for instance in aws_instance.worker_nodes : instance.private_ip]
}
