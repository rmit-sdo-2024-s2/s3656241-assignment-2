# Output the public hostname of the EC2 instance
output "vm_public_hostname" {
  value = aws_instance.app[*].public_dns
}