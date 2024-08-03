provider "aws" {
  region = "us-east-1"
}

# Create VPC
resource "aws_vpc" "main" {
  cidr_block = "10.0.0.0/16"
}

# Create Subnets
resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.1.0/24"
}

resource "aws_subnet" "private" {
  vpc_id     = aws_vpc.main.id
  cidr_block = "10.0.2.0/24"
}

# Create Internet Gateway
resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.main.id
}

# Create Route Table for Public Subnet
resource "aws_route_table" "public" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }
}

resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public.id
  route_table_id = aws_route_table.public.id
}

# Create Elastic IP for NAT Gateway
resource "aws_eip" "nat" {
}

# Create NAT Gateway
resource "aws_nat_gateway" "nat" {
  allocation_id = aws_eip.nat.id
  subnet_id     = aws_subnet.public.id
}

resource "aws_route_table" "private" {
  vpc_id = aws_vpc.main.id

  route {
    cidr_block     = "0.0.0.0/0"
    nat_gateway_id = aws_nat_gateway.nat.id
  }
}

resource "aws_route_table_association" "private" {
  subnet_id      = aws_subnet.private.id
  route_table_id = aws_route_table.private.id
}

# Create Security Group for Bastion Host
resource "aws_security_group" "bastion" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["203.0.113.0/32"]  # Replace with your actual IP address
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Security Group for Kubernetes Nodes
resource "aws_security_group" "kubernetes" {
  vpc_id = aws_vpc.main.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion.id]
  }

  ingress {
    from_port   = 6443
    to_port     = 6443
    protocol    = "tcp"
    security_groups = [aws_security_group.kubernetes.id]
  }

  ingress {
    from_port   = 10250
    to_port     = 10250
    protocol    = "tcp"
    security_groups = [aws_security_group.kubernetes.id]
  }

  ingress {
    from_port   = 10251
    to_port     = 10251
    protocol    = "tcp"
    security_groups = [aws_security_group.kubernetes.id]
  }

  ingress {
    from_port   = 10252
    to_port     = 10252
    protocol    = "tcp"
    security_groups = [aws_security_group.kubernetes.id]
  }

  ingress {
    from_port   = 10255
    to_port     = 10255
    protocol    = "tcp"
    security_groups = [aws_security_group.kubernetes.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

# Create Bastion Host
resource "aws_instance" "bastion" {
  ami                    = "<ami-id>"
  instance_type          = "t2.micro"
  key_name               = "<key-pair-name>"
  subnet_id              = aws_subnet.public.id
  vpc_security_group_ids = [aws_security_group.bastion.id]

  user_data = <<-EOF
              #!/bin/bash
              yum update -y
              yum install -y aws-cli
              EOF
}

# Create Control Plane Node
resource "aws_instance" "control_plane" {
  ami                    = "<ami-id>"
  instance_type          = "t2.medium"
  key_name               = "<key-pair-name>"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.kubernetes.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              apt-get install -y apt-transport-https curl
              curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
              cat <<EOF2 >/etc/apt/sources.list.d/kubernetes.list
              deb http://apt.kubernetes.io/ kubernetes-xenial main
              EOF2
              apt-get update -y
              apt-get install -y kubelet kubeadm kubectl
              kubeadm init --pod-network-cidr=10.244.0.0/16
              mkdir -p $HOME/.kube
              cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
              chown $(id -u):$(id -g) $HOME/.kube/config
              kubectl apply -f https://raw.githubusercontent.com/coreos/flannel/master/Documentation/kube-flannel.yml
              EOF
}

# Create Data Plane Nodes
resource "aws_instance" "data_plane" {
  count                  = 2
  ami                    = "<ami-id>"
  instance_type          = "t2.medium"
  key_name               = "<key-pair-name>"
  subnet_id              = aws_subnet.private.id
  vpc_security_group_ids = [aws_security_group.kubernetes.id]

  user_data = <<-EOF
              #!/bin/bash
              apt-get update -y
              apt-get install -y docker.io
              systemctl start docker
              systemctl enable docker
              apt-get install -y apt-transport-https curl
              curl -s https://packages.cloud.google.com/apt/doc/apt-key.gpg | apt-key add -
              cat <<EOF2 >/etc/apt/sources.list.d/kubernetes.list
              deb http://apt.kubernetes.io/ kubernetes-xenial main
              EOF2
              apt-get update -y
              apt-get install -y kubelet kubeadm kubectl
              kubeadm join <control-plane-private-ip>:6443 --token <token> --discovery-token-ca-cert-hash sha256:<hash>
              EOF
}

# comment for testing