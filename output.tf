//
// Identify any values that need to be returned to the calling modules
//

output "vpc_id" {
  value = aws_vpc.theVPC.id
}

output "public_subnet_ids" {
  value = aws_subnet.public-subnets.*.id
}

output "private_subnet_ids" {
  value = aws_subnet.private-subnets.*.id
}

output "public_subnet_cidr" {
  value = aws_subnet.public-subnets.*.cidr_block
}

output "private_subnet_cidr" {
  value = aws_subnet.private-subnets.*.cidr_block
}
