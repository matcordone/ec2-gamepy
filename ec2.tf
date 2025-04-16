resource "aws_instance" "myec2vm" {
  instance_type          = var.instance_type
  ami                    = data.aws_ami.myec2ami.id
  key_name               = var.instance_keypair
  user_data              = file("install-game.sh")
  subnet_id              = aws_subnet.myec2subnet.id
  vpc_security_group_ids = [aws_security_group.myec2sg.id]
  tags = {
    name = "EC2 Demo"
  }
}
data "aws_ami" "myec2ami" {
  most_recent = true
  owners      = ["amazon"]
  filter {
    name   = "name"
    values = ["amzn2-ami-hvm-*-x86_64-gp2"]
  }
  filter {
    name   = "architecture"
    values = ["x86_64"]
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
  filter {
    name   = "root-device-type"
    values = ["ebs"]
  }
}
