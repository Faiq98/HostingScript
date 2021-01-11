# Hosting Script
Basic auto installation script for hosting your website.

Test on Ubuntu 18.04 (LTS) x64
- [x] Digital Ocean
- [x] UpCloud
- [x] Free Tier GCP

P.S: Please install swap for Free Tier GCP

wget https://raw.githubusercontent.com/Faiq98/HostingScript/master/env/InstallSwap.sh&&chmod +x InstallSwap.sh&&./InstallSwap.sh

## Java Hosting
### What install inside the server
* Tomcat
* MySQL
* PhpMyAdmin
* SSL

wget https://raw.githubusercontent.com/Faiq98/HostingScript/master/JavaInstaller.sh&&chmod +x JavaInstaller.sh&&./JavaInstaller.sh

## Php Hosting
### What install inside the server
* Apache
* MySQL
* PhpMyAdmin
* SSL

wget https://raw.githubusercontent.com/Faiq98/HostingScript/master/PhpInstaller.sh&&chmod +x PhpInstaller.sh&&./PhpInstaller.sh