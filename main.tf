provider "aws" {
  region = "us-east-1"
}

# VPC

resource "aws_vpc" "apache_vpc" {
  cidr_block = "10.0.0.0/16"
  tags = {
    Name = "apache_vpc"
  }
}

# Internet Gateway which will connect public subnet to internet.

resource "aws_internet_gateway" "vpc_igw" {
  vpc_id = aws_vpc.apache_vpc.id

  tags = {
    Name = "vpc_igw"
  }
}

# Nat Gateway which will give private instances access to internet.

resource "aws_nat_gateway" "ngw" {
  connectivity_type = "private"
  subnet_id         = aws_subnet.pub_apache_subnet.id

  tags = {
    Name = "nat_gw"
  }
}

# Public subnet, where webserver/public instances will be.

resource "aws_subnet" "pub_apache_subnet" {
  vpc_id                  = aws_vpc.apache_vpc.id
  cidr_block              = "10.0.0.0/20"
  map_public_ip_on_launch = true
  tags = {
    Name = "public_apache_sub"
  }
}

# Private Subnet, where private instances will be.

resource "aws_subnet" "priv_apache_subnet" {
  vpc_id     = aws_vpc.apache_vpc.id
  cidr_block = "10.0.16.0/20"
  tags = {
    Name = "priv_apache_sub"
  }
}

# Routing tables for both Private and Public Subnets.

resource "aws_route_table" "public_rt" {
  vpc_id = aws_vpc.apache_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_internet_gateway.vpc_igw.id
  }

  depends_on = [aws_internet_gateway.vpc_igw]

  tags = {
    Name = "Public_RT"
  }
}

resource "aws_route_table" "private_rt" {
  vpc_id = aws_vpc.apache_vpc.id

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = aws_nat_gateway.ngw.id
  }

  depends_on = [aws_nat_gateway.ngw]

  tags = {
    Name = "Private_RT"
  }
}

# Associates route tables with subnets

resource "aws_route_table_association" "pubsub-rt" {
  subnet_id      = aws_subnet.pub_apache_subnet.id
  route_table_id = aws_route_table.public_rt.id

}

resource "aws_route_table_association" "privsub-rt" {
  subnet_id      = aws_subnet.priv_apache_subnet.id
  route_table_id = aws_route_table.private_rt.id
}

# Webserver Security Group

resource "aws_security_group" "websg" {

  description = "Allow ssh http inbound traffic"
  vpc_id      = aws_vpc.apache_vpc.id

  ingress {
    description      = "SSH from VPC"
    from_port        = 22
    to_port          = 22
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTP from VPC"
    from_port        = 80
    to_port          = 80
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  ingress {
    description      = "HTTPS from VPC"
    from_port        = 443
    to_port          = 443
    protocol         = "tcp"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags = {
    Name = "allow_ssh_http_https"
  }
}


# Web Server

resource "aws_instance" "web" {
  ami             = "ami-0b5eea76982371e91"
  instance_type   = "t2.micro"
  subnet_id       = aws_subnet.pub_apache_subnet.id
  security_groups = [aws_security_group.websg.id]

  # User-data script. Runs updates, installs, web server, PHP, mariadb

  user_data = <<-EOF
  #!/bin/bash   
  yum update -y
  sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
  sudo yum install -y httpd mariadb-server
  sudo service httpd restart
  echo "Hello World from $(hostname -f)" > /var/www/html/index.html
  sudo systemctl start mariadb
  echo "<?php phpinfo() ?>" > /var/www/html/test.php
  cd /var/www/html
  sudo wget https://wordpress.org/latest.zip
  sudo unzip latest.zip
  mv wordpress blog
  cd /var/www/html/blog
  mv wp-config-sample.php wp-config.php
  EOF


  tags = {
    Name = "Webserver"
  }

}

# EIP for Webserver instance

resource "aws_eip" "elasticip" {
  instance = aws_instance.web.id
}


# Database Server (currently no security group associated. Will need to configure server and add SG in console as needed.)

resource "aws_instance" "database" {
  ami           = "ami-0b5eea76982371e91"
  instance_type = "t2.micro"
  subnet_id     = aws_subnet.priv_apache_subnet.id


  tags = {
    Name = "Database"
  }

}

# Outputs

output "eip" {
  value = aws_eip.elasticip.public_ip
}
