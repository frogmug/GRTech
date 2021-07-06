provider "aws" {
  region = "us-east-2"
}

terraform {
  backend "s3" {
    bucket = "grtech-tfstate"
    key    = "vmTerraform/terraform.tfstate"
    region = "us-east-2"
  }
}

#-------------------------------------------------------------------------
#----------------------------EBS Volume-----------------------------------
#Create the volume used with the ec2 instance 
resource "aws_ebs_volume" "grtech_ebs_volume" {
  availability_zone = "us-east-2b"
  size              = 1
  type              = "gp2"

  tags = {
    Name = "GRTech"
  }
}

resource "aws_volume_attachment" "ebc_volume_attachment" {
  device_name = "/dev/xvdh"
  volume_id   = aws_ebs_volume.grtech_ebs_volume.id
  instance_id = aws_instance.grtech_vm.id
} 

#-------------------------------------------------------------------------
#----------------------------Security Group-------------------------------

#Create security group with firewall rules and connected static IP (personal machine)
resource "aws_security_group" "grtech_security_group" {
  name        = "grtech_security_group"
  description = "security group for GRTechVM - Allow traffic from HTTP and SSH"
  vpc_id      = aws_vpc.grtech_vpc.id
  
 # http through port 80
  ingress {
    from_port   = 80
    to_port     = 80
    protocol    = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

 # SSH from my local machine
 ingress {
    from_port   = 22
    to_port     = 22
    protocol    = "tcp"
    cidr_blocks = ["47.223.216.174/32"]
  }

 # outbound to anywhere
  egress {
    from_port        = 0
    to_port          = 0
    protocol         = "-1"
    cidr_blocks      = ["0.0.0.0/0"]
    ipv6_cidr_blocks = ["::/0"]
  }

  tags= {
   Name = "GRTech"
  }
}

#-------------------------------------------------------------------------
#----------------------------Network--------------------------------------

resource "aws_vpc" "grtech_vpc" {
  cidr_block = "10.0.0.0/16"
}

resource "aws_internet_gateway" "grtech_gateway" {
  vpc_id = aws_vpc.grtech_vpc.id
}

resource "aws_subnet" "grtech_subnet" {
  vpc_id            = aws_vpc.grtech_vpc.id
  cidr_block        = "10.0.0.0/24"
  availability_zone = "us-east-2b"
}

resource "aws_route_table" "grtech_route_table" {
  vpc_id = aws_vpc.grtech_vpc.id
}

resource "aws_route" "grtech_route" {
  route_table_id         = aws_route_table.grtech_route_table.id
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.grtech_gateway.id
}

 resource "aws_route_table_association" "grtech_public_assoc" {
  subnet_id      = aws_subnet.grtech_subnet.id
  route_table_id = aws_route_table.grtech_route_table.id
} 

 resource "aws_eip" "grtech_eip" {
  #instance = aws_instance.grtech_vm.id
  vpc = true
}

resource "aws_eip_association" "grtech_eip_assoc" {
  instance_id   = aws_instance.grtech_vm.id
  allocation_id = aws_eip.grtech_eip.id
}
 
#-------------------------------------------------------------------------
#----------------------------Instance-------------------------------------

#Create EC2 Instance for VM
resource "aws_instance" "grtech_vm" {
  ami           = "ami-0277b52859bac6f4b"
  subnet_id     = aws_subnet.grtech_subnet.id
  instance_type = "t2.micro"
  associate_public_ip_address = true

  # Security group to be assign to instance
  vpc_security_group_ids = [aws_security_group.grtech_security_group.id]

  #!!!Orignally being used. However, error states it is smaller than the expected 8gb during terraform apply process
/*root_block_device {
    volume_size = 1
    volume_type = "gp2"
  } 
*/

  #user data to install and set up webpage, and set file system for volume drive.
   user_data = file("userdata/userdata.sh")

  # key name
  key_name = "GRTechVMs2"

  tags = {
    Name = "GRTech"
  }

}