# Provisions a spot EC2 instance with 
# Zone for AMI is 
# us-west-2
# us-east-2

provider "aws" {
  region = "us-east-2"
}

resource "aws_vpc" "test-env" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  enable_dns_support   = true
}

resource "aws_subnet" "subnet-uno" {
  # creates a subnet
  cidr_block        = "${cidrsubnet(aws_vpc.test-env.cidr_block, 3, 1)}"
  vpc_id            = "${aws_vpc.test-env.id}"
  availability_zone = "us-east-2a"
}

resource "aws_security_group" "ingress-ssh-test" {
  name   = "allow-ssh-sg"
  vpc_id = "${aws_vpc.test-env.id}"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]

    from_port = 22
    to_port   = 22
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress-http-test" {
  name   = "allow-http-sg"
  vpc_id = "${aws_vpc.test-env.id}"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]

    from_port = 80
    to_port   = 80
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_security_group" "ingress-https-test" {
  name   = "allow-https-sg"
  vpc_id = "${aws_vpc.test-env.id}"

  ingress {
    cidr_blocks = [
      "0.0.0.0/0"
    ]

    from_port = 443
    to_port   = 443
    protocol  = "tcp"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

resource "aws_eip" "ip-test-env" {
  instance = "${aws_spot_instance_request.test_worker.spot_instance_id}"
  vpc      = true
}

resource "aws_internet_gateway" "test-env-gw" {
  vpc_id = "${aws_vpc.test-env.id}"
}

resource "aws_route_table" "route-table-test-env" {
  vpc_id = "${aws_vpc.test-env.id}"

  route {
    cidr_block = "0.0.0.0/0"
    gateway_id = "${aws_internet_gateway.test-env-gw.id}"
  }
}

resource "aws_route_table_association" "subnet-association" {
  subnet_id      = "${aws_subnet.subnet-uno.id}"
  route_table_id = "${aws_route_table.route-table-test-env.id}"
}

## Orgeon ami-094125af156557ca2
## Ohio ami-0cc87e5027adcdca8


resource "aws_spot_instance_request" "test_worker" {
  ami                    = "ami-0cc87e5027adcdca8" 
  spot_price             = "0.0035"
  instance_type          = "t2.micro"
  spot_type              = "one-time"
  block_duration_minutes = "0"
  wait_for_fulfillment   = "true"
  key_name               = "abril_17"  
  security_groups = ["${aws_security_group.ingress-ssh-test.id}", "${aws_security_group.ingress-http-test.id}",
  "${aws_security_group.ingress-https-test.id}"]
  subnet_id = "${aws_subnet.subnet-uno.id}"
    user_data = <<EOF
#!/bin/bash

#### Executando Instalando um PHP para docker com sail (https://www.youtube.com/watch?v=R2lS_rORCQE)

#### Passo 1: Instala Docker

sudo yum -y update

sudo yum -y install docker 

#### #### Passo 2: Ativando Docker

sudo systemctl restart docker

#### #### Passo 3: Usuario comum Docker

sudo usermod -a -G docker ec2-user
sudo id ec2-user
sudo newgrp docker

#### #### #### Passo 4: Instalando Composer

sudo curl -L https://github.com/docker/compose/releases/latest/download/docker-compose-$(uname -s)-$(uname -m) -o /usr/local/bin/docker-compose

sudo chmod +x /usr/local/bin/docker-compose

docker-compose version

#### #### #### #### Passo 5: Instalando Composer

#### 

#### 

cd /home/ec2-user

mkdir fev242023

cd  fev242023

wget https://raw.githubusercontent.com/tderflinger/terraform-ec2-spot/master/terraform/spot-ec2.tf

curl -s https://laravel.build/laravel-dev-blog | bash

cd laravel-dev-blog/

wget https://raw.githubusercontent.com/tderflinger/terraform-ec2-spot/master/terraform/spot-ec2.tf

./vendor/bin/sail up

EOF
}
