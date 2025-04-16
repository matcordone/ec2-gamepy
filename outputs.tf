output "instance_public_ip" {
  value = aws_instance.myec2vm.public_ip
}