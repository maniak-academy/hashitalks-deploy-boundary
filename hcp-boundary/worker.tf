
resource "aws_instance" "worker_ec2" {
  ami                         = "ami-0fc5d935ebf8bc3bc" # Replace with the latest Ubuntu 20.04 AMI in your region
  instance_type               = "t2.micro"
  subnet_id                   = module.vpc.public_subnets[0] # Replace this with the public subnet ID in your VPC
  key_name                    = aws_key_pair.workerssh.key_name
  associate_public_ip_address = true                              # This line is added to associate a public IP
  vpc_security_group_ids      = [aws_security_group.worker_sg.id] # Attach the security group

  user_data = <<-EOF
              #!/bin/bash
              mkdir -p /home/ubuntu/boundary/config
              cd /home/ubuntu/boundary/

              # Install Boundary
              curl -fsSL https://apt.releases.hashicorp.com/gpg | sudo apt-key add -
              sudo apt-add-repository "deb [arch=amd64] https://apt.releases.hashicorp.com $(lsb_release -cs) main"
              sudo apt-get update && sudo apt-get install boundary-enterprise -y

              # Create the configuration script
              cat <<EOT > /home/ubuntu/my_config.hcl
              disable_mlock = true

              listener "tcp" {
                address = "0.0.0.0:9203"
                purpose = "proxy"
              }

              worker {
                initial_upstreams = ["ca5c49f3-a488-26a4-918c-eaafa7ff439d.proxy.boundary.hashicorp.cloud:9202"]
                auth_storage_path = "/home/ubuntu/boundary/worker"
                tags {
                  type = ["workeraws"]
                }
              }
              EOT
              # start boundary

              boundary server -config=/home/ubuntu/my_config.hcl
              EOF
  tags = {
    Name = "workerServer"
  }
}

resource "aws_security_group" "worker_sg" {
  name        = "worker_sg"
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
    Name = "worker_sg"
  }
}

resource "tls_private_key" "workerssh" {
  algorithm = "RSA"
}

resource "aws_key_pair" "workerssh" {
  key_name   = "workerssh" # Set a simple name for the key pair
  public_key = tls_private_key.workerssh.public_key_openssh
}

resource "null_resource" "key" {
  # Ensures the key is created before trying to create the file
  depends_on = [aws_key_pair.workerssh]

  provisioner "local-exec" {
    command = "echo \"${tls_private_key.workerssh.private_key_pem}\" > workerssh.pem"
  }

  provisioner "local-exec" {
    command = "chmod 600 workerssh.pem"
  }

  provisioner "local-exec" {
    when    = destroy
    command = "rm -f workerssh.pem"
  }
}