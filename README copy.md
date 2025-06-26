# terraform-ansible-aws-bastion

![Screenshot 2025-06-26 at 1 43 41 PM](https://github.com/user-attachments/assets/afce6e71-b018-4a11-a8c0-1fd087811c67)

![terraform-ansible-aws-bastion drawio](https://github.com/user-attachments/assets/858740e4-3f63-4749-a778-6579835bbca6)

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
    - SSH from trusted IP: "{{ MyIP }}"/32
    - ICMP from trusted IP: "{{ MyIP }}"/32
    - All traffic from private subnet: 10.0.0.16/28
  - **Outbound:**
    - All traffic allowed to "{{ MyIP }}"/32
    - All traffic to private subnet: 10.0.0.16/28
- **Route Table:**
  - `0.0.0.0/0` → Internet Gateway
  - `10.0.0.0/24` → Local

**Private Subnet:**

- **CIDR:** 10.0.0.16/28
- **Network ACL (NACL):**
  - **Inbound:**
    - SSH from public subnet: 10.0.0.0/28
    - ICMP from public subnet: 10.0.0.0/28
    - All traffic from public subnet: 10.0.0.0/28
  - **Outbound:**
    - All traffic to public subnet: 10.0.0.0/28
- **Route Table:**
  - `10.0.0.0/24` → Local

---

### Instances

**Bastion Host:**

- **Deployed in the public subnet**
- **Public IP:** "{{ elastic_ip_address }}"
- **Key pair:** "{{ your_key_pair }}"
- **Security Group:**
  - **Inbound:**
    - SSH from trusted IP: "{{ MyIP }}"/32
    - ICMP from trusted IP: "{{ MyIP }}"/32
    - All traffic from private subnet: 10.0.0.16/28
  - **Outbound:**
    - All traffic to trusted IP: "{{ MyIP }}"/32
- **Hostname:** terrable.demo.bastion
- **Ansible tasks:**
  - Enable SSH forwarding (`AllowTcpForwarding yes`, `GatewayPorts yes`)
  - Update `/etc/hosts` for DNS resolution
  - Transfer private key for resource server access

**Resource Server:**

- **Deployed in the private subnet**
- **No public IP**
- **Key pair:** resource_key
- **Security Group:**
  - **Inbound:**
    - SSH from bastion host
    - ICMP from bastion host
  - **Outbound:**
    - All traffic to bastion host
- **Hostname:** terrable.demo.resource
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
 
## Local Files that are editted by Ansible Playbook:

**In my local host:**

Append the `~/.ssh/config` file to include:

```console
Host terrable.demo.bastion bastion_public_ip
  HostName bastion_public_ip
  User ec2-user
  IdentityFile /Users/beedydo/Desktop/"{{ your_key_pair }}"

Host terrable.demo.resource resource_private_ip
  HostName resource_private_ip
  User ec2-user
  IdentityFile /Users/beedydo/Desktop/"{{ your_resource_key }}"
  ProxyJump terrable.demo.bastion
```

---

**Bastion host:**

- **Change hostname to:** `terrable.demo.bastion`
- **Append the `/etc/ssh/sshd_config` file to include:**

```console
AllowTcpForwarding yes
GatewayPorts yes
```

- **Send the private key "{{ your_resource_key }}" from localhost to bastion host and store it in `~/.ssh`**
- **Append `~/.ssh/config`:**

```console
Host resource
  HostName 10.0.0.21
  IdentityFile ~/.ssh/"{{ your_resource_key }}"
```

- **Append the `/etc/hosts` file to include:**

```console
bastion_public_ip bastion_private_IP terrable.demo.bastion
resource_private_ip terrable.demo.resource
```

---

**Resource server:**

- **Change hostname to:** `terrable.demo.resource`
- **Within the instance, also create:**
- **A user called:** `admin`
- **With password:** `admin`
- **Append the `/etc/hosts` file to include:**

```console
bastion_public_ip bastion_private_IP terrable.demo.bastion
resource_private_ip terrable.demo.resource
```

## Before running Terraform script:

```console
export AWS_ACCESS_KEY_ID="YOUR_ACCESS_KEY"
export AWS_SECRET_ACCESS_KEY="YOUR_SECRET_KEY"
export AWS_REGION="ap-southeast-1"
```

## Assumptions:

- key-pairs are managed and stored on AWS
  - use cloud-init to provide keys managed outside of AWS
