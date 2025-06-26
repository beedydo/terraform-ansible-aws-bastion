# AWS Configuration
variable "aws_region" {
  description = "AWS region to deploy resources"
  type        = string
  default     = "ap-southeast-1"
}

variable "my_public_ip" {
  description = "Your public IP address (leave blank to auto-detect)"
  type        = string
  default     = ""
}

# VPC Configuration
variable "vpc_cidr" {
  description = "VPC CIDR block"
  type        = string
  default     = "10.0.0.0/24"
}

variable "vpc_name" {
  description = "VPC name tag"
  type        = string
  default     = "terra-ble-vpc"
}

# Subnet Configuration
variable "public_subnet_cidr" {
  description = "Public subnet CIDR block"
  type        = string
  default     = "10.0.0.0/28"
}

variable "private_subnet_cidr" {
  description = "Private subnet CIDR block"
  type        = string
  default     = "10.0.0.16/28"
}

variable "availability_zone" {
  description = "Availability zone for subnets"
  type        = string
  default     = "ap-southeast-1a"
}

# Resource Names
variable "internet_gateway_name" {
  description = "Internet Gateway name tag"
  type        = string
  default     = "terrable-demo-igw"
}

variable "public_subnet_name" {
  description = "Public subnet name tag"
  type        = string
  default     = "public-subnet"
}

variable "private_subnet_name" {
  description = "Private subnet name tag"
  type        = string
  default     = "private-subnet"
}

variable "public_route_table_name" {
  description = "Public route table name tag"
  type        = string
  default     = "public-rt"
}

variable "private_route_table_name" {
  description = "Private route table name tag"
  type        = string
  default     = "private-rt"
}

variable "public_nacl_name" {
  description = "Public NACL name tag"
  type        = string
  default     = "public-nacl"
}

variable "private_nacl_name" {
  description = "Private NACL name tag"
  type        = string
  default     = "private-nacl"
}

# Security Groups
variable "bastion_security_group_name" {
  description = "Bastion security group name"
  type        = string
  default     = "bastion-sg"
}

variable "resource_security_group_name" {
  description = "Resource server security group name"
  type        = string
  default     = "resource-sg"
}

# Bastion Host Configuration
variable "bastion_instance_ami" {
  description = "Bastion instance AMI"
  type        = string
  default     = "ami-0b3ee461e1e36d519" # RHEL
}

variable "bastion_instance_type" {
  description = "Bastion instance type"
  type        = string
  default     = "t2.micro"
}

variable "bastion_key_name" {
  description = "Bastion SSH key name"
  type        = string
  default     = "interview-demo-key"
}

variable "bastion_instance_name" {
  description = "Bastion instance name tag"
  type        = string
  default     = "terrable-bastion"
}

variable "bastion_eip_allocation_id" {
  description = "Bastion Elastic IP allocation ID"
  type        = string
  default     = "eipalloc-034c8030b7da5b3f4"
}

# Resource Server Configuration
variable "resource_instance_ami" {
  description = "Resource server AMI"
  type        = string
  default     = "ami-0b3ee461e1e36d519" # RHEL
}

variable "resource_instance_type" {
  description = "Resource server instance type"
  type        = string
  default     = "t2.micro"
}

variable "resource_key_name" {
  description = "Resource server SSH key name"
  type        = string
  default     = "resource_key"
}

variable "resource_instance_name" {
  description = "Resource server instance name tag"
  type        = string
  default     = "terrable-resource"
}

variable "bastion_hostname" {
  description = "Hostname for the bastion host"
  type        = string
  default     = "terrable.demo.bastion"
}

variable "resource_hostname" {
  description = "Hostname for the resource server"
  type        = string
  default     = "terrable.demo.resource"
}

variable "remote_user" {
  description = "Remote user for SSH connections"
  type        = string
  default     = "ec2-user"
}

variable "local_ssh_key_path" {
  description = "Local path to SSH keys"
  type        = string
  default     = "/Users/beedydo/.ssh"
}
