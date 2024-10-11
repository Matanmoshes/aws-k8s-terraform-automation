# Bastion Host
resource "aws_instance" "bastion" {
  ami                    = var.ubuntu_ami
  instance_type          = var.bastion_instance_type
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]
  key_name               = var.key_pair_name

  tags = {
    Name = "bastion-host"
  }
}

# Elastic IP for Bastion Host
resource "aws_eip" "bastion_eip" {
  instance = aws_instance.bastion.id
  domain   = "vpc"

  depends_on = [aws_internet_gateway.gw]

  tags = {
    Name = "bastion-eip"
  }
}

# Ansible Control Machine
resource "aws_instance" "ansible_control" {
  ami                    = var.ubuntu_ami
  instance_type          = var.ansible_instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.key_pair_name
  user_data = file("${path.module}/ansible-setup.yaml")

  tags = {
    Name = "ansible-control"
  }
}

# Kubernetes Control Plane Node
resource "aws_instance" "control_plane" {
  ami                    = var.ubuntu_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.key_pair_name

  tags = {
    Name = "control-plane"
  }
}

# Kubernetes Worker Nodes
resource "aws_instance" "worker_nodes" {
  count                  = var.worker_count
  ami                    = var.ubuntu_ami
  instance_type          = var.instance_type
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.private_sg.id]
  key_name               = var.key_pair_name

  tags = {
    Name = "worker-node-${count.index + 1}"
  }
}
