provider "aws" {
  region = "ap-south-1"
  access_key = "MINKR4965HTJQ72MONQ"
  secret_key = "F9F4I3qpYBnL3mq6S63c1wzeIzcmtnsFHR4o7OW"
}
# resource "<provider>_<resource_type>" "name" {
#     config options.....
#       key = "value"
#       key2 = "another value"
    
# }
# resource "aws_instance" "mero-first-server" {
#   ami           = "ami-03f4878755434977f"
#   instance_type = "t2.micro"
#    tags = {
#     Name = "ubuntu"
#   }

# }

# resource "aws_vpc" "suruko-vpc" {
#   cidr_block = "10.0.0.0/16"
#    tags = {
#     Name = "production"
#   }
# }

# resource "aws_subnet" "subnet-1" {
#   vpc_id     = aws_vpc.suruko-vpc.id
#   cidr_block = "10.0.1.0/24"

#   tags = {
#     Name = "prod-subnet"
#   }
# }

# resource "aws_vpc" "doshro-vpc" {
#   cidr_block = "10.1.0.0/16"
#    tags = {
#     Name = "Dev"
#   }
# }

# resource "aws_subnet" "subnet-2" {
#   vpc_id     = aws_vpc.doshro-vpc.id
#   cidr_block = "10.1.1.0/24"

#   tags = {
#     Name = "dev-subnet"
#   }
# }


# ------------Project1---------------

# 1. Create VPC

resource "aws_vpc" "project1-vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "Project1"
  }
}

# 2. Create Internet Gateway

resource "aws_internet_gateway" "gw" {
  vpc_id = aws_vpc.project1-vpc.id
}

# 3. Create Custom Route table

resource "aws_route_table" "project1-route-table" {
  vpc_id = aws_vpc.project1-vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  route {
    ipv6_cidr_block        = "::/0"
    gateway_id = aws_internet_gateway.gw.id
  }

  tags = {
    Name = "Project1-route-table"
  }
}

# 4. Create a Subnet

resource "aws_subnet" "subnet-1" {
  vpc_id     = aws_vpc.project1-vpc.id
  cidr_block = "10.0.1.0/24"
  availability_zone = "ap-south-1a"

  tags = {
    Name = "Project1-subnet"
  }
}

# 5. Associate subnet with Route table

resource "aws_route_table_association" "a" {
  subnet_id      = aws_subnet.subnet-1.id
  route_table_id = aws_route_table.project1-route-table.id
}


# 6. Create Security Group

resource "aws_security_group" "allow_web" {
  name        = "allow_web_traffic"
  description = "Allow Web inbound traffic"
  vpc_id      = aws_vpc.project1-vpc.id

ingress{
  description = "HTTPS from VPC"
  from_port        = 443
  to_port          = 443
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
}

ingress{
  description = "HTTP from VPC"
  from_port        = 80
  to_port          = 80
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
}

ingress{
  description = "SSH from VPC"
  from_port        = 22
  to_port          = 22
  protocol         = "tcp"
  cidr_blocks      = ["0.0.0.0/0"]
}

egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    # ipv6_cidr_blocks = ["::/0"]
  }
  tags = {
    Name = "allow_web_traffic"
  }
}
# resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv4" {
#   security_group_id = aws_security_group.allow_web.id
#   cidr_ipv4         = "0.0.0.0/0"
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

# resource "aws_vpc_security_group_ingress_rule" "allow_tls_ipv6" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv6         = "::/0"
#   from_port         = 443
#   ip_protocol       = "tcp"
#   to_port           = 443
# }

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv4" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv4         = "0.0.0.0/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

# resource "aws_vpc_security_group_egress_rule" "allow_all_traffic_ipv6" {
#   security_group_id = aws_security_group.allow_tls.id
#   cidr_ipv6         = "::/0"
#   ip_protocol       = "-1" # semantically equivalent to all ports
# }

# 7. Create a network interface
resource "aws_network_interface" "web-server-nic" {
  subnet_id       = aws_subnet.subnet-1.id
  private_ips     = ["10.0.1.50"]
  security_groups = [aws_security_group.allow_web.id]

}

# 8. Assign an elastic IP
resource "aws_eip" "one" {
  domain                    = "vpc"
  network_interface         = aws_network_interface.web-server-nic.id
  associate_with_private_ip = "10.0.1.50"
  depends_on = [aws_internet_gateway.gw]
}

# 9. Create Ubantu server

resource "aws_instance" "web-server-instance" {
  ami = "ami-007020fd9c84e18c7"
  instance_type = "t2.micro"
  availability_zone = "ap-south-1a"
  key_name = "Terraform-demo-key"

  network_interface {
    device_index = 0
    network_interface_id = aws_network_interface.web-server-nic.id
  }
  user_data = <<-EOF
              sudo apt update -y
              sudo apt install apache2 -y
              sudo systemct1 start apache2
              sudo bash -c 'echo your first web server > /var/www/html/index.html
              EOF
  tags = {
    Name = "web-server"
  }
}