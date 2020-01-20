#!/bin/sh

#update package
sudo apt update

#install default package
sudo apt install mysql-server

#Config MySQL
sudo mysql_secure_installation

#Adjusting User Auth & Privilagr
sudo mysql
ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';
FLUSH PRIVILEGES;
exit

#Check MySQL status
systemctl status mysql.service