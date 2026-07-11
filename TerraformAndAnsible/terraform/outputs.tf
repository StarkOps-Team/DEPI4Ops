output "controller_public_ip" {
  value = aws_instance.controller.public_ip
}

output "target_public_ip" {
  value = aws_instance.target.public_ip
}

output "target_private_ip" {
  value = aws_instance.target.private_ip
}

output "ssh_private_key_path" {
  value = local_file.private_key.filename
}

output "ssh_to_controller" {
  value = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.controller.public_ip}"
}

output "ssh_to_target" {
  value = "ssh -i ${local_file.private_key.filename} ubuntu@${aws_instance.target.public_ip}"
}
