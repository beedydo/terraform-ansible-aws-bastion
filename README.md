# terraform-ansible-aws-bastionAdd commentMore actions

![Screenshot 2025-06-23 at 1 14 29 AM](https://github.com/user-attachments/assets/f7e96471-cf76-42b1-97d0-2beffe89a024)

<img width="1225" alt="Screenshot 2025-06-23 at 11 32 14 AM" src="https://github.com/user-attachments/assets/030e5694-457f-4947-a820-b95855dc47d4" />
![Screenshot 2025-06-26 at 1 43 41 PM](https://github.com/user-attachments/assets/afce6e71-b018-4a11-a8c0-1fd087811c67)

![terraform-ansible-aws-bastion drawio](https://github.com/user-attachments/assets/858740e4-3f63-4749-a778-6579835bbca6)

# AWS Bastion Host Infrastructure as Code (Terraform + Ansible)

@@ -39,11 +38,12 @@
- **CIDR:** 10.0.0.0/28
- **Network ACL (NACL):**
  - **Inbound:**
    - SSH from trusted IP: 220.255.73.250/32
    - ICMP from trusted IP: 220.255.73.250/32
    - SSH from trusted IP: "{{ MyIP }}"/32
    - ICMP from trusted IP: "{{ MyIP }}"/32
    - All traffic from private subnet: 10.0.0.16/28
  - **Outbound:**
    - All traffic allowed
    - All traffic allowed to "{{ MyIP }}"/32
    - All traffic to private subnet: 10.0.0.16/28
- **Route Table:**
  - `0.0.0.0/0` → Internet Gateway
  - `10.0.0.0/24` → Local
@@ -54,7 +54,7 @@
- **Network ACL (NACL):**
  - **Inbound:**
    - SSH from public subnet: 10.0.0.0/28
    - ICMP from trusted IP: 220.255.73.250/32
    - ICMP from public subnet: 10.0.0.0/28
    - All traffic from public subnet: 10.0.0.0/28
  - **Outbound:**
    - All traffic to public subnet: 10.0.0.0/28
@@ -68,16 +68,16 @@
**Bastion Host:**

- **Deployed in the public subnet**
- **Public IP:** 18.142.141.30 (Elastic IP)
- **Key pair:** interview-demo-key
- **Public IP:** "{{ elastic_ip_address }}"
- **Key pair:** "{{ your_key_pair }}"
- **Security Group:**
  - **Inbound:**
    - SSH from trusted IP: 220.255.73.250/32
    - ICMP from trusted IP: 220.255.73.250/32
    - SSH from trusted IP: "{{ MyIP }}"/32
    - ICMP from trusted IP: "{{ MyIP }}"/32
    - All traffic from private subnet: 10.0.0.16/28
  - **Outbound:**
    - All traffic to trusted IP: 220.255.73.250/32
- **Hostname:** interview.demo.bastion
    - All traffic to trusted IP: "{{ MyIP }}"/32
- **Hostname:** terrable.demo.bastion
- **Ansible tasks:**
  - Enable SSH forwarding (`AllowTcpForwarding yes`, `GatewayPorts yes`)
  - Update `/etc/hosts` for DNS resolution
@@ -87,14 +87,14 @@

- **Deployed in the private subnet**
- **No public IP**
- **Key pair:** resource-key
- **Key pair:** resource_key
- **Security Group:**
  - **Inbound:**
    - SSH from bastion host
    - ICMP from bastion host
  - **Outbound:**
    - All traffic to bastion host
- **Hostname:** interview.demo.resource
- **Hostname:** terrable.demo.resource
- **Ansible tasks:**
  - Create user: admin with password admin
  - Update `/etc/hosts` for DNS resolution
@@ -118,70 +118,70 @@
Append the `~/.ssh/config` file to include:

```console
Host interview.demo.bastion
Host terrable.demo.bastion bastion_public_ip
  HostName bastion_public_ip
  User ec2-user
  IdentityFile /Users/beedydo/Desktop/interview-demo-key.pem
  IdentityFile /Users/beedydo/Desktop/"{{ your_key_pair }}"

Host interview.demo.resource
Host terrable.demo.resource resource_private_ip
  HostName resource_private_ip
  User ec2-user
  IdentityFile /Users/beedydo/Desktop/resource_key
  ProxyJump interview.demo.bastion
  IdentityFile /Users/beedydo/Desktop/"{{ your_resource_key }}"
  ProxyJump terrable.demo.bastion
```

---

**Bastion host:**

- **Change hostname to:** `interview.demo.bastion`
- **Change hostname to:** `terrable.demo.bastion`
- **Append the `/etc/ssh/sshd_config` file to include:**

```console
AllowTcpForwarding yes
GatewayPorts yes
```

- **Send the private key “resource_key” from localhost to bastion host and store it in `~/.ssh`**
- **Send the private key "{{ your_resource_key }}" from localhost to bastion host and store it in `~/.ssh`**
- **Append `~/.ssh/config`:**

```console
Host resource
  HostName 10.0.0.21
  IdentityFile ~/.ssh/resource_key
  IdentityFile ~/.ssh/"{{ your_resource_key }}"
```

- **Append the `/etc/hosts` file to include:**

```console
bastion_public_ip bastion_private_IP interview.demo.bastion
resource_private_ip interview.demo.resource
bastion_public_ip bastion_private_IP terrable.demo.bastion
resource_private_ip terrable.demo.resource
```

---

**Resource server:**

- **Change hostname to:** `interview.demo.resource`
- **Change hostname to:** `terrable.demo.resource`
- **Within the instance, also create:**
- **A user called:** `admin`
- **With password:** `admin`
- **Append the `/etc/hosts` file to include:**

```console
bastion_public_ip bastion_private_IP interview.demo.bastion
resource_private_ip interview.demo.resource
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