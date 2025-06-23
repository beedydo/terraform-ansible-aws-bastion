# terraform-ansible-aws-bastion
Deploy a secure AWS bastion host and resource server with Terraform infrastructure and Ansible configuration.

![Screenshot 2025-06-23 at 1 14 29 AM](https://github.com/user-attachments/assets/f7e96471-cf76-42b1-97d0-2beffe89a024)

# AWS Bastion Host Infrastructure as Code (Terraform + Ansible)

This project automates the deployment of a secure AWS bastion host and resource server using Terraform for infrastructure provisioning and Ansible for configuration management.

---

## Overview

- **Infrastructure as Code:** Terraform provisions AWS resources, while Ansible handles server configuration.
- **Secure Architecture:** Implements a bastion host in a public subnet and a resource server in a private subnet, with strict network access controls.
- **SSH Access:** Only allows SSH and ICMP from trusted IPs, with bastion host acting as the sole entry point to the resource server.

---

## Key Components

### AWS Infrastructure

**VPC:**

- **Region:** ap-southeast-1
- **CIDR:** 10.0.0.0/24

**Internet Gateway:**

- Attached to the VPC for public internet access.

**Subnets:**

**Public Subnet:**

- **CIDR:** 10.0.0.0/28
- **Network ACL (NACL):**
  - **Inbound:**
    - SSH from trusted IP: 220.255.73.250/32
    - ICMP from trusted IP: 220.255.73.250/32
    - All traffic from private subnet: 10.0.0.16/28
  - **Outbound:**
    - All traffic allowed
- **Route Table:**
  - `0.0.0.0/0` → Internet Gateway
  - `10.0.0.0/24` → Local

**Private Subnet:**

- **CIDR:** 10.0.0.16/28
- **Network ACL (NACL):**
  - **Inbound:**
    - SSH from public subnet: 10.0.0.0/28
    - ICMP from trusted IP: 220.255.73.250/32
    - All traffic from public subnet: 10.0.0.0/28
  - **Outbound:**
    - All traffic to public subnet: 10.0.0.0/28
- **Route Table:**
  - `10.0.0.0/24` → Local

---

### Instances

**Bastion Host:**

- **Deployed in the public subnet**
- **Public IP:** 18.142.141.30 (Elastic IP)
- **Key pair:** interview-demo-key
- **Security Group:**
  - **Inbound:**
    - SSH from trusted IP: 220.255.73.250/32
    - ICMP from trusted IP: 220.255.73.250/32
    - All traffic from private subnet: 10.0.0.16/28
  - **Outbound:**
    - All traffic to trusted IP: 220.255.73.250/32
- **Hostname:** interview.demo.bastion
- **Ansible tasks:**
  - Enable SSH forwarding (`AllowTcpForwarding yes`, `GatewayPorts yes`)
  - Update `/etc/hosts` for DNS resolution
  - Transfer private key for resource server access

**Resource Server:**

- **Deployed in the private subnet**
- **No public IP**
- **Key pair:** resource-key
- **Security Group:**
  - **Inbound:**
    - SSH from bastion host
    - ICMP from bastion host
  - **Outbound:**
    - All traffic to bastion host
- **Hostname:** interview.demo.resource
- **Ansible tasks:**
  - Create user: admin with password admin
  - Update `/etc/hosts` for DNS resolution

---

## Ansible Configuration

- **Local Host:**
  - Configure SSH client for bastion and resource server access via ProxyJump
- **Bastion Host:**
  - Configure SSH config for seamless access to the resource server
  - Transfer and store resource server private key
- **Resource Server:**
  - Configure hostname and user account
