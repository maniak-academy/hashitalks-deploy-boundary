output "worker_public_ip" {
  value = aws_instance.worker_ec2.public_ip
}