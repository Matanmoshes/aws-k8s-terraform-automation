# AWS Kubernetes Cluster Automation

This project automates the deployment of a highly available Kubernetes cluster on AWS using Terraform and Ansible. It leverages Infrastructure as Code (IaC) to provision the necessary AWS resources and configure the Kubernetes environment seamlessly.

---

## Project Overview

In this project, I automated the creation of a Kubernetes cluster on AWS by orchestrating infrastructure provisioning with Terraform and configuration management with Ansible. The setup includes:

- **AWS Infrastructure:** VPC, subnets, security groups, EC2 instances (control plane and worker nodes), and necessary networking components.
- **Terraform Backend:** S3 bucket for storing Terraform state and DynamoDB for state locking.
- **Ansible Automation:** Provisioning and configuring Kubernetes components, installing containerd, kubelet, kubeadm, kubectl, and deploying the Calico network plugin.
- **CI/CD Integration:** Automated deployment using GitHub Actions to trigger Terraform and Ansible workflows.

---

## Folder Structure

Here's an overview of the project directory structure:

```
aws-k8s-terraform-automation/
├── README.md
├── ansible
│   ├── ansible-setup.sh
│   ├── ansible.cfg
│   ├── inventory.ini
│   └── kubernetes-setup.yml
└── terraform
    ├── ansible-setup.yaml
    ├── backend.tf
    ├── instances.tf
    ├── outputs.tf
    ├── security_groups.tf
    ├── terraform.tfvars
    ├── variable.tf
    └── vpc.tf
```

### Description of Directories and Files

- **ansible/**
  - `ansible-setup.sh`: Script to initialize Ansible environment.
  - `ansible.cfg`: Ansible configuration file.
  - `inventory.ini`: Inventory file listing control plane and worker nodes.
  - `kubernetes-setup.yml`: Ansible playbook for setting up Kubernetes cluster.

- **terraform/**
  - `ansible-setup.yaml`: Terraform configuration for Ansible setup.
  - `backend.tf`: Configuration for Terraform backend using S3 and DynamoDB.
  - `instances.tf`: Defines EC2 instances for control plane and workers.
  - `outputs.tf`: Outputs from Terraform deployment.
  - `security_groups.tf`: Security group configurations.
  - `terraform.tfvars`: Variable definitions for Terraform.
  - `variable.tf`: Terraform variable declarations.
  - `vpc.tf`: VPC and networking configurations.

---
## Architecture Diagram

Below is a high-level diagram of the AWS infrastructure and the deployment flow:

```SCSS
                                    Internet
                                        |
                                        |
                                 [Public IP Address]
                                        |
                                        |
                                   ┌───────────┐
                                   │ Bastion   │
                                   │   Host    │
                                   └───────────┘
                                        |
                         SSH over Public IP (Port 22)
                                        |
                             ───────────────────────
                             |                    |
                      ┌─────────────┐       ┌─────────────┐
                      │  Virtual    │       │  Network    │
                      │  Network    │       │  Security   │
                      │  (VNet)     │       │  Groups     │
                      └─────────────┘       └─────────────┘
                             |                    |
                ┌──────────────────────────┐      |
                |        10.0.0.0/16       |      |
                |                          |      |
        ┌──────────────────┐      ┌──────────────────┐
        |  Public Subnet   |      |  Private Subnet  |
        |   10.0.1.0/24    |      |   10.0.2.0/24    |
        └──────────────────┘      └──────────────────┘
                |                          |
                |                          |
        ┌─────────────┐             ┌───────────────────────┐
        │ Bastion     │             │ Ansible Control VM    │
        │   Host      │             │ Control Plane VM      │
        └─────────────┘             │ Worker Node 1         │
                                    │ Worker Node 2         │
                                    └───────────────────────┘
                |                          | 
                |                          |
         SSH via Private IP           Internal Networking
          (Port 22 allowed)             (Kubernetes Traffic)
                |                          |
                |                          |
        ┌─────────────┐             ┌───────────────────────┐
        │  Storage    │────────────▶│ Managed Disks for VMs │
        │  Accounts   │             └───────────────────────┘
        └─────────────┘

```

---

## Prerequisites

Before you begin, ensure you have met the following requirements:

- **AWS Account:** You must have an active AWS account.
- **Terraform Installed:** [Download Terraform](https://www.terraform.io/downloads.html) and ensure it's added to your PATH.
- **Ansible Installed:** [Install Ansible](https://docs.ansible.com/ansible/latest/installation_guide/intro_installation.html).
- **GitHub Repository:** A GitHub repository to host the project code and GitHub Actions workflows.
- **AWS CLI Configured:** [Configure AWS CLI](https://docs.aws.amazon.com/cli/latest/userguide/cli-configure-quickstart.html) with your credentials.
- **SSH Client:** Ensure you have an SSH client installed for connecting to AWS instances.

---

## Setup and Deployment

## 1. AWS Setup

1. **Create SSH Key Pair:**
   - Log in to the AWS Management Console.
   - Navigate to **EC2 > Key Pairs**.
   - Create a new key pair named `ansible-key` and download the `.pem` file.

2. **Create S3 Bucket for Terraform Backend:**
   - Go to **S3** service.
   - Create a bucket named `terraform-backend-bucket-ioioio21`.

3. **Create DynamoDB Table for State Locking:**
   - Navigate to **DynamoDB**.
   - Create a table named `state_locking` with `LockID` as the primary key.

---

## 2. Terraform Deployment

1. **Configure Terraform Backend:**
   - Update `terraform/backend.tf` with your AWS S3 bucket and DynamoDB table details.

2. **Initialize Terraform:**
   ```bash
   cd terraform
   terraform init
   ```

3. **Apply Terraform Configuration:**
   ```bash
   terraform apply
   ```
   - Review the plan and confirm to provision the resources.

---

## 3. Ansible Configuration

1. **Set Up SSH Key Permissions:**
   ```bash
   chmod 400 ~/Downloads/ansible-key.pem
   ```

2. **Transfer SSH Key to Bastion VM:**
   ```bash
   scp -i ~/Downloads/ansible-key.pem ~/Downloads/ansible-key.pem ubuntu@<Bastion_IP>:/home/ubuntu/.ssh/
   ```

3. **SSH into Bastion VM:**
   ```bash
   ssh -i ~/Downloads/ansible-key.pem ubuntu@<Bastion_IP>
   ```

4. **Set Permissions on Bastion VM:**
   ```bash
   sudo chmod 600 ~/.ssh/ansible-key.pem
   ```

5. **Transfer SSH Key to Ansible Control VM:**
   ```bash
   scp -i ~/.ssh/ansible-key.pem ~/.ssh/ansible-key.pem ubuntu@<Ansible_Control_VM_IP>:/home/ubuntu/.ssh/
   ```

6. **SSH into Ansible Control VM:**
   ```bash
   ssh -i ~/.ssh/ansible-key.pem ubuntu@<Ansible_Control_VM_IP>
   ```

7. **Update Inventory File:**
   - Navigate to the project directory:
     ```bash
     cd ~/aws-k8s-terraform-automation/ansible
     ```
   - Update `inventory.ini` with the correct IP addresses of your VMs.

8. **Verify SSH Connectivity with Ansible:**
   ```bash
   ansible all -m ping
   ```
   - You should receive a "pong" response from all hosts.

---

## 4. Kubernetes Cluster Initialization

1. **Run the Ansible Playbook:**
   ```bash
   ansible-playbook -i inventory.ini kubernetes-setup.yml
   ```
   - The playbook will configure the Kubernetes control plane and join worker nodes to the cluster.

2. **Verify the Kubernetes Cluster:**
   - SSH into the Control Plane VM:
     ```bash
     ssh -i ~/.ssh/ansible-key.pem ubuntu@10.0.2.144
     ```
   - Check the status of the nodes:
     ```bash
     kubectl get nodes
     ```

   **Expected Output:**
   ```plaintext
   NAME            STATUS   ROLES           AGE     VERSION
   ip-10-0-2-144   Ready    control-plane   9m19s   v1.29.9
   ip-10-0-2-185   Ready    <none>          27s     v1.29.9
   ip-10-0-2-222   Ready    <none>          27s     v1.29.9
   ```

---

## Verification

After completing the setup, ensure that your Kubernetes cluster is operational:

1. **Check Node Status:**
   - All nodes should be in the `Ready` state.
   - Control plane node should have the `control-plane` role.
   - Worker nodes should have `<none>` under roles.

2. **Deploy a Test Application:**
   - Deploy a simple NGINX application to verify the cluster functionality.
     ```bash
     kubectl create deployment nginx --image=nginx
     kubectl expose deployment nginx --port=80 --type=LoadBalancer
     kubectl get pods
     kubectl get services
     ```

3. **Monitor Cluster Health:**
   - Use Kubernetes Dashboard or other monitoring tools to keep an eye on cluster health and performance.


