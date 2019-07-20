# unifi-scripts

[UniFi Installation Scripts | UniFi Easy Update Script | Ubuntu 16.04, 18.04, 18.10, 19.04 | Debian 8, 9 and 10](https://community.ui.com/questions/ccbc7530-dd61-40a7-82ec-22b17f027776)

Instructions:

1) Copy the link location of the script.

2) SSH into your Ubuntu/Debian machine, and login as root. ( Ubuntu | sudo -i | Debian | su )

2a) Make sure the ca-certificates package is installed.

apt-get update; apt-get install ca-certificates wget -y
3) Download the script by executing the following command. ( change it to your wanted version )

wget https://get.glennr.nl/unifi/install/unifi-5.10.25.sh
4) Make the script executable ( change it to the script version you downloaded )

chmod +x unifi-5.10.25.sh
5) After you downloaded the script and made it executable you need to run it, by executing the following command.

./unifi-5.10.25.sh
6) Once the installation is completed browse to your controller.

https://ip.of.your.server:8443