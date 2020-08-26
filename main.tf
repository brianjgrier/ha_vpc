# AWS Virtual Privat Cloud

data "aws_availability_zones" "available" {
  state = "available"
}


resource "aws_vpc" "theVPC" {
  cidr_block = var.CIDR
  instance_tenancy = "default"
  enable_dns_support = "true"
  enable_dns_hostnames = "true"
  enable_classiclink = "false"
  tags = merge(var.Tags, {"Name" = var.VPC_Name})
}

//
// Now we need to create the internet gateway for the VPC.
// This is done for you when you use the GUI
//

resource "aws_internet_gateway" "igw" {
  vpc_id = aws_vpc.theVPC.id
  tags = merge(var.Tags, {"Name" = var.VPC_Name})
}

resource "aws_subnet" "public-subnets" {
  vpc_id = aws_vpc.theVPC.id
  count = min(var.Public_Subnets, length(data.aws_availability_zones.available.names), length(var.EIP_List))
  cidr_block = cidrsubnet(var.CIDR, 8, count.index)
  tags = merge(var.Tags, {"Name" = format("%s: public-${count.index+1}", var.VPC_Name)})
  depends_on = [aws_internet_gateway.igw]
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

resource "aws_subnet" "private-subnets" {
  vpc_id = aws_vpc.theVPC.id
  count = min(var.Private_Subnets, length(data.aws_availability_zones.available.names), length(var.EIP_List))
  cidr_block = cidrsubnet(var.CIDR, 8, length(aws_subnet.public-subnets) + count.index)
  tags = merge(var.Tags, {"Name" = format("%s: private-${count.index+1}", var.VPC_Name)}) 
  depends_on = [aws_internet_gateway.igw]
  availability_zone = element(data.aws_availability_zones.available.names, count.index)
}

//
// Now we have to create the NAT Gateway(s) and associate them with a bastion-nat subnet
//

resource "aws_nat_gateway" "ghe_access" {
  count = length(aws_subnet.public-subnets)
  allocation_id = element(var.EIP_List, count.index)
  subnet_id = element(aws_subnet.public-subnets.*.id, count.index)
  tags = merge(var.Tags, {"Name" = format("%s: NAT-${count.index+1}", var.VPC_Name)})
}

resource "aws_route_table" "public-rt" {
  count = length(aws_nat_gateway.ghe_access)

  vpc_id       = aws_vpc.theVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.igw.id
  }

  tags = merge(var.Tags, {"Name" = format("%s: public-rt-${count.index+1}", var.VPC_Name)})
}


resource "aws_route_table" "private-rt" {
  count = length(aws_nat_gateway.ghe_access)
  vpc_id       = aws_vpc.theVPC.id

  route {
    cidr_block = "0.0.0.0/0"
    nat_gateway_id = element(aws_nat_gateway.ghe_access.*.id, count.index)
  }
  tags = merge(var.Tags, {"Name" = format("%s: private-rt-${count.index+1}", var.VPC_Name)})
}

//
//  Now associate the route table with the public subnet - giving
//  all public subnet outbound instances access to the internet.
//

resource "aws_route_table_association" "public-subnets" {
  count          = var.Public_Subnets
  subnet_id      = element(aws_subnet.public-subnets.*.id, count.index)
  route_table_id = element(aws_route_table.public-rt.*.id, count.index)
}

//
// The private subnets also need outbound access so they can get updates and such
//

resource "aws_route_table_association" "private-subnets" {
  count          = var.Private_Subnets
  subnet_id      = element(aws_subnet.private-subnets.*.id, count.index)
  route_table_id = element(aws_route_table.private-rt.*.id, count.index)
}


#resource "aws_route_table_association" "bastion-subnets" {
#  count          = var.Bastion_Subnets
#  subnet_id      = element(aws_subnet.bastion-nat-subnets.*.id, count.index)
#  route_table_id = element(aws_route_table.bastion-rt.*.id, count.index)
#}

//
// Now we have to create the security group for the bastion servers we are baout to set up.
// 

resource "aws_security_group" "bastion_SG" {
  vpc_id = aws_vpc.theVPC.id
#  name = "bastion security group"

  ingress {
#    cidr_blocks = [ "64.100.0.0/14", "72.163.0.0/16", "128.107.0.0/16", "144.254.0.0/16", "173.36.0.0/14" ] 
    cidr_blocks = var.Company_IPs
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }

  egress {
    cidr_blocks = [ var.CIDR ]
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
  }
  tags = merge(var.Tags, {"Name" = format("%s: Bastion_SG", var.VPC_Name)})
}


resource "aws_instance" "bastion" {
  count                       = var.Public_Subnets
  ami                         = var.AMI_List[var.AWS_Region]
  instance_type               = "t2.micro"
  associate_public_ip_address = true
  key_name                    = var.SSH_Keypair
  subnet_id                   = element(aws_subnet.public-subnets.*.id, count.index)
  vpc_security_group_ids      = [aws_security_group.bastion_SG.id]
  root_block_device {
    encrypted = true
  }
  tags                        = merge(var.Tags, {"Name" = format("%s: Bastion-${count.index+1}", var.VPC_Name)})
  volume_tags                 = merge(var.Tags, {"Name" = format("%s: Bastion-${count.index+1}", var.VPC_Name)})
}
