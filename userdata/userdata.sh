#!/bin/bash

# mount an EBS volume to EC2 Linux
sudo mkfs -t xfs /dev/xvdh
sudo mkdir /newvolume
sudo mount /dev/xvdh /newvolume/

# partition the 1 gig volume. Currently does not work as desired.
#parted /dev/xvdh
#mklabel gpt
#unit s
#mkpart primary ext4 0% 100%
#quit

# automount EBS Volume on Reboot
cat  /etc/fstab
sudo cp /etc/fstab /etc/fstab.bak
echo '/dev/xvdh       /newvolume   ext4    defaults,nofail        0       0' >> fstab.bak
sudo mount -a # check if there is no errors


# install and set up webpage
sudo yum update -y
sudo amazon-linux-extras install -y lamp-mariadb10.2-php7.2 php7.2
cat /etc/system-release
sudo yum install -y httpd mariadb-server
sudo systemctl start httpd
sudo systemctl enable httpd
sudo systemctl is-enabled httpd
echo "<h1>Hello GR World</h1>" > /var/www/html/index.html
