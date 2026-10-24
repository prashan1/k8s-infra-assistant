output "public_ip" {
  value = aws_eip.node.public_ip
}

output "instance_id" {
  value = aws_instance.node.id
}

output "ssm_shell_command" {
  value = "aws ssm start-session --target ${aws_instance.node.id} --region ${var.region}"
}
