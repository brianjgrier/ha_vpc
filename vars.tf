# AWS Virtual Privat Cloud

variable "AWS_Region" {
  type = string
  description = "The AWS regon to create the VPC in"
}

variable "SSH_Keypair" {
  type = string
  description = "The keypair to use for the bastion server"
}

variable "AMI_List" {
  type = map
  description = "The list of AMIs to be used to create the bastion server"
}

variable "CIDR" {
  type = string
  description = "The address range that AWS will allocate for this VPC"
}

variable "Public_Subnets" {
  type = number
  description = "The number of Subnets that need to be created for tin the VPC"
}

variable "Private_Subnets" {
  type = number
  description = "The number of Subnets that need to be created for tin the VPC"
}

variable "Bastion_Subnets" {
  type = number
  description = "The number of Subnets that need to be created for tin the VPC"
}

variable "Tags" {
  type = map
  description = "The tags to be applied to the VPC"
}

variable "VPC_Name" {
  type = string
  description = "The name to be applied to the VPC"
}

variable "EIP_List" {
  type = list
  description = "The list of EIP resources that are available"
}

variable "GHE_CIDR_def" {
  type = string
  description = "The IP address of the GitHub Enterprise instance this VPC needs to access"
}

variable "Company_IPs" {
  type = list
}
