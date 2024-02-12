
resource "aws_instance" "linux_ec2" {
  ami                         = "ami-0fc5d935ebf8bc3bc" # Replace with the latest Ubuntu 20.04 AMI in your region
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnets[0] # Replace this with the public subnet ID in your VPC
  key_name                    = aws_key_pair.linuxssh.key_name
  associate_public_ip_address = true                             # This line is added to associate a public IP
  vpc_security_group_ids      = [aws_security_group.linux_sg.id] # Attach the security group
  user_data                   = <<-EOF
              #!/bin/bash
              wget -O- https://apt.releases.hashicorp.com/gpg | sudo gpg --dearmor -o /usr/share/keyrings/hashicorp-archive-keyring.gpg
              echo "deb [signed-by=/usr/share/keyrings/hashicorp-archive-keyring.gpg] https://apt.releases.hashicorp.com $(lsb_release -cs) main" | sudo tee /etc/apt/sources.list.d/hashicorp.list
              sudo apt update && sudo apt install vault
              EOF
  tags = {
    Name = "linuxServer"
  }
}

resource "aws_security_group" "linux_sg" {
  name        = "linux_sg"
  description = "Allow inbound traffic on port 22 all outbound traffic"
  vpc_id      = module.vpc.vpc_id # Replace this with your VPC ID if needed


  ingress {
    description = "SSH Private Traffic"
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"] # Allows traffic from any IP address. Narrow this down as necessary for your use case.
  }
  egress {
    description = "All traffic"
    from_port   = 0
    to_port     = 0
    protocol    = "-1"          # Allows all traffic
    cidr_blocks = ["0.0.0.0/0"] # Allows traffic to any IP address
  }

  tags = {
    Name = "linux_sg"
  }
}

resource "tls_private_key" "linuxssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "linuxssh" {
  key_name   = "linuxssh" # Set a simple name for the key pair
  public_key = tls_private_key.linuxssh.public_key_openssh
}

resource "null_resource" "linuxkey" {
  # Ensures the key is created before trying to create the file
  depends_on = [aws_key_pair.linuxssh]

  provisioner "local-exec" {
    command = "echo \"${tls_private_key.linuxssh.private_key_pem}\" > linuxssh.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 linuxssh.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f linuxssh.pem"
  }
}