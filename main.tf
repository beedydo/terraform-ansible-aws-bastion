provider "aws" {
  region = "ap-southeast-1"
}

# Fetching and storing My_IP
data "http" "myip" {
  url = "https://ipv4.icanhazip.com"
}

locals {
  # Use the variable if set, otherwise use the auto-detected IP with /32
  public_ip = coalesce(var.my_public_ip, "${chomp(data.http.myip.response_body)}/32")
}

# VPC
resource "aws_vpc" "terra_ble_vpc" {
  cidr_block = "10.0.0.0/24"
  enable_dns_support = true
  enable_dns_hostnames = true
  tags = {
    Name = "terra-ble-vpc"
  }
}

# Internet Gateway
resource "aws_internet_gateway" "terrable_demo_igw" {
  vpc_id = aws_vpc.terra_ble_vpc.id
  tags = {
    Name = "terrable-demo-igw"
  }
}

# Public Subnet
resource "aws_subnet" "public_subnet" {
  vpc_id            = aws_vpc.terra_ble_vpc.id
  cidr_block        = "10.0.0.0/28"
  availability_zone = "ap-southeast-1a"
  map_public_ip_on_launch = true
  tags = {
    Name = "public-subnet"
  }
}

# Private Subnet
resource "aws_subnet" "private_subnet" {
  vpc_id            = aws_vpc.terra_ble_vpc.id
  cidr_block        = "10.0.0.16/28"
  availability_zone = "ap-southeast-1a"
  tags = {
    Name = "private-subnet"
  }
}

# Public Route Table (Corrected)
resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.terra_ble_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.terrable_demo_igw.id
  }

  route {
    cidr_block = "10.0.0.0/24"
    gateway_id = "local"
  }

  tags = {
    Name = "public-rt"
  }
}

# Associate Public Route Table with Public Subnet
resource "aws_route_table_association" "public_rt_assoc" {
  subnet_id      = aws_subnet.public_subnet.id
  route_table_id = aws_route_table.public_rt.id
}

# Public NACL
resource "aws_network_acl" "public_nacl" {
  vpc_id = aws_vpc.terra_ble_vpc.id
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
    cidr_block = "10.0.0.16/28"
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
    Name = "public-nacl"
  }
}

# Private NACL
resource "aws_network_acl" "private_nacl" {
  vpc_id = aws_vpc.terra_ble_vpc.id
  subnet_ids = [aws_subnet.private_subnet.id]

  ingress {
    protocol   = "tcp"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.16/28"
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
    cidr_block = "10.0.0.0/28"
    from_port  = 0
    to_port    = 0
  }

  egress {
    protocol   = "-1"
    rule_no    = 100
    action     = "allow"
    cidr_block = "10.0.0.0/28"
    from_port  = 0
    to_port    = 0
  }

  tags = {
    Name = "private-nacl"
  }
}

# Private Route Table
resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.terra_ble_vpc.id

  route {
    cidr_block = "10.0.0.0/24"
    gateway_id = "local"
  }

  tags = {
    Name = "private-rt"
  }
}

resource "aws_route_table_association" "private_rt_assoc" {
  subnet_id      = aws_subnet.private_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Bastion Security Group
resource "aws_security_group" "bastion_sg" {
  name        = "bastion-sg"
  description = "Security group for bastion host"
  vpc_id      = aws_vpc.terra_ble_vpc.id

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
    cidr_blocks = ["10.0.0.16/28"]
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
    cidr_blocks = ["10.0.0.16/28"]
  }

  tags = {
    Name = "bastion-sg"
  }
}

# Resource Security Group
resource "aws_security_group" "resource_sg" {
  name        = "resource-sg"
  description = "Security group for resource server"
  vpc_id      = aws_vpc.terra_ble_vpc.id

  ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  ingress {
    from_port   = -1 # ICMP
    to_port     = -1
    protocol    = "icmp"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    security_groups = [aws_security_group.bastion_sg.id]
  }

  tags = {
    Name = "resource-sg"
  }
}

# Bastion Host
resource "aws_instance" "bastion" {
  ami           = "ami-0b3ee461e1e36d519" # RHEL
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.public_subnet.id
  key_name      = "interview-demo-key" # Replace with own key
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.bastion_sg.id]

  tags = {
    Name = "terrable-bastion"
  }
}

resource "aws_eip_association" "bastion_eip" {
  instance_id   = aws_instance.bastion.id
  allocation_id = "eipalloc-034c8030b7da5b3f4"
}

# Resource Server
resource "aws_instance" "resource" {
  ami           = "ami-0b3ee461e1e36d519" # RHEL
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.private_subnet.id
  key_name      = "resource_key.pub"
  associate_public_ip_address = false
  vpc_security_group_ids = [aws_security_group.resource_sg.id]

  tags = {
    Name = "terrable-resource"
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
    # Ansible variables generated by Terraform
    bastion_elastic_ip: ${aws_eip_association.bastion_eip.public_ip}
    bastion_private_ip: ${aws_instance.bastion.private_ip}
    resource_private_ip: ${aws_instance.resource.private_ip}
  EOF
  depends_on = [
    aws_instance.bastion,
    aws_instance.resource,
    aws_eip_association.bastion_eip
  ]
}

# Update Inventory File Dynamically
resource "local_file" "ansible_inventory" {
  filename = "ansible/inventory.ini"
  content  = <<-EOT
    [bastion_host]
    ${aws_eip_association.bastion_eip.public_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/interview-demo-key.pem

    [resource_server]
    ${aws_instance.resource.private_ip} ansible_user=ec2-user ansible_ssh_private_key_file=~/.ssh/resource_key
  EOT

  # Wait for resources to be provisioned
  depends_on = [
    aws_instance.bastion,
    aws_instance.resource,
    aws_eip_association.bastion_eip
  ]
}

# Run Ansible Playbook
resource "null_resource" "run_ansible" {
  triggers = {
    # Re-run when outputs change
    outputs = sha1(jsonencode([
      aws_eip_association.bastion_eip.public_ip,
      aws_instance.bastion.private_ip,
      aws_instance.resource.private_ip
    ]))
  }

  provisioner "local-exec" {
    command = <<-EOT
      sleep 60  # Wait for instance to initialize
      ANSIBLE_HOST_KEY_CHECKING=False \
      ansible-playbook \
        -i ansible/inventory.ini \
        --extra-vars '@ansible/vars.yml' \
        ansible/configure.yml
    EOT
  }
}