provider "aws" {
  region = var.aws_region
}

# Fetching and storing My_IP
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  public_ip = coalesce(var.my_public_ip, "${chomp(data.http.myip.response_body)}/32")
}

# VPC
resource "aws_vpc" "terr_ible_vpc" {
  cidr_block           = var.vpc_cidr
  enable_dns_support   = true
  enable_dns_hostnames = true
  tags = {
    Name = var.vpc_name
  }
}

# Internet Gateway
resource "aws_internet_gateway" "terrible_demo_igw" {
  vpc_id = aws_vpc.terr_ible_vpc.id
  tags = {
    Name = var.internet_gateway_name
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id                  = aws_vpc.terr_ible_vpc.id
  cidr_block              = var.public_subnet_cidr
  availability_zone       = var.availability_zone
  map_public_ip_on_launch = true
  tags = {
    Name = var.public_subnet_name
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.terr_ible_vpc.id
  cidr_block        = var.private_subnet_cidr
  availability_zone = var.availability_zone
  tags = {
    Name = var.private_subnet_name
  }
}

# Public Route Table
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.terr_ible_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terrible_demo_igw.id
  }

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }

  tags = {
    Name = var.public_route_table_name
  }
}

# Associate Public Route Table
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Public NACL
resource "aws_network_acl" "public_nacl" {
  vpc_id     = aws_vpc.terr_ible_vpc.id
  subnet_ids = [aws_subnet.public_subnet.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = local.public_ip
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "icmp"
    rule_no    = 200
    action     = "allow"
    cidr_block = local.public_ip
    icmp_type  = 8
    icmp_code  = 0
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 300
    action     = "allow"
    cidr_block = var.private_subnet_cidr
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "0.0.0.0/0"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = var.public_nacl_name
  }
}

# Private NACL
resource "aws_network_acl" "private_nacl" {
  vpc_id     = aws_vpc.terr_ible_vpc.id
  subnet_ids = [aws_subnet.private_subnet.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.public_subnet_cidr
    from_port  = 22
    to_port    = 22
  }

  ingress {
    protocol   = "icmp"
    rule_no    = 200
    action     = "allow"
    cidr_block = local.public_ip
    icmp_type  = 8
    icmp_code  = 0
    from_port  = 0
    to_port    = 0
  }

  ingress {
    protocol   = "-1"
    rule_no    = 300
    action     = "allow"
    cidr_block = var.public_subnet_cidr
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = var.public_subnet_cidr
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = var.private_nacl_name
  }
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.terr_ible_vpc.id

  route {
    cidr_block = var.vpc_cidr
    gateway_id = "local"
  }

  tags = {
    Name = var.private_route_table_name
  }
}

resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Bastion Security Group
resource "aws_security_group" "bastion_sg" {
  name        = var.bastion_security_group_name
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.terr_ible_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = [local.public_ip]
  }

  ingress {
    from_port   = -1 # ICMP
    to_port     = -1
    protocol    = "icmp"
    cidr_blocks = [local.public_ip]
  }

  ingress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.private_subnet_cidr]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [local.public_ip]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = [var.private_subnet_cidr]
  }

  tags = {
    Name = var.bastion_security_group_name
  }
}

# Resource Security Group
resource "aws_security_group" "resource_sg" {
  name        = var.resource_security_group_name
  description = "Security group for resource server"
  vpc_id      = aws_vpc.terr_ible_vpc.id

  ingress {
    from_port       = 22
    to_port         = 22
    protocol        = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    from_port       = -1 # ICMP
    to_port         = -1
    protocol        = "icmp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port       = 0
    to_port         = 0
    protocol        = "-1"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  tags = {
    Name = var.resource_security_group_name
  }
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami           = var.bastion_instance_ami
  instance_type = var.bastion_instance_type
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = var.bastion_key_name
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = var.bastion_instance_name
  }
}

resource "aws_eip_association" "bastion_eip" {
  instance_id   = aws_instance.bastion.id
  allocation_id = var.bastion_eip_allocation_id
}

# Resource Server
resource "aws_instance" "resource" {
  ami           = var.resource_instance_ami
  instance_type = var.resource_instance_type
  subnet_id     = aws_subnet.private_subnet.id
  key_name      = var.resource_key_name
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.resource_sg.id]

  tags = {
    Name = var.resource_instance_name
  }
}

# Output Variables
output "bastion_elastic_ip" {
  value = aws_eip_association.bastion_eip.public_ip
}

output "bastion_private_ip" {
  value = aws_instance.bastion.private_ip
}

output "resource_private_ip" {
  value = aws_instance.resource.private_ip
}

# Generate Ansible variables file
resource "local_file" "ansible_vars" {
  filename = "ansible/vars.yml"
  content  = <<-EOF
    # Terraform-generated IPs
    bastion_elastic_ip: ${aws_eip_association.bastion_eip.public_ip}
    bastion_private_ip: ${aws_instance.bastion.private_ip}
    resource_private_ip: ${aws_instance.resource.private_ip}
    
    # Hostname Configuration
    bastion_hostname: ${var.bastion_hostname}
    resource_hostname: ${var.resource_hostname}
    
    # User Configuration
    remote_user: ${var.remote_user}
    
    # Path Configuration
    local_ssh_key_path: ${var.local_ssh_key_path}
    
    # Key Names
    bastion_key_name: ${var.bastion_key_name}
    resource_key_name: ${var.resource_key_name}
  EOF
  depends_on = [
    aws_instance.bastion,
    aws_instance.resource,
    aws_eip_association.bastion_eip
  ]
}

# Update Inventory File
resource "local_file" "ansible_inventory" {
  filename = "ansible/inventory.ini"
  content  = <<-EOT
    [bastion_host]
    ${aws_eip_association.bastion_eip.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/${var.bastion_key_name}.pem

    [resource_server]
    ${aws_instance.resource.private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/${replace(var.resource_key_name, ".pub", "")}
  EOT
  depends_on = [
    aws_instance.bastion,
    aws_instance.resource,
    aws_eip_association.bastion_eip
  ]
}

# Run Ansible Playbook
resource "null_resource" "run_ansible" {
  triggers = {
    outputs = sha1(jsonencode([
      aws_eip_association.bastion_eip.public_ip,
      aws_instance.bastion.private_ip,
      aws_instance.resource.private_ip
    ]))
  }

  provisioner "local-exec" {
    command = <<-EOT
      sleep 120
      ANSIBLE_HOST_KEY_CHECKING=False \
      ansible-playbook \
        -i ansible/inventory.ini \
        --private-key ~/.ssh/${var.bastion_key_name}.pem \
        --extra-vars '@ansible/vars.yml' \
        ansible/configure.yml
    EOT
  }
}
