#!/bin/sh

#update package
sudo apt update

#install default package
sudo apt install mysql-server

#Config MySQL
sudo mysql_secure_installation

#Adjusting User Auth & Privilagr

CMD1="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY 'password';"
CMD2="FLUSH PRIVILEGES;"
CMD3="exit"
sudo mysql -Bse "$CMD1;$CMD2;$CMD3"

#Check MySQL status
systemctl status mysql.service