#!/bin/sh

myip=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | head -n1`;

echo

if [ $USER != 'root' ]; then
	echo "Sorry, for run the script please using root user"
	exit
fi
echo "
Java Hosting Auto Installer..."
sleep 2
clear

echo "Start Auto Installer...."
sleep 2
clear

#update package
sudo apt update

#install JDK package
sudo apt install default-jdk -y

#create tomcat group
sudo groupadd tomcat

#create new tomcat user
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

#change directory to tmp
cd /tmp

#download tomcat
curl -O https://downloads.apache.org/tomcat/tomcat-9/v9.0.31/bin/apache-tomcat-9.0.31.tar.gz

#create tomcat directory and extract the archive
sudo mkdir /opt/tomcat
sudo tar xzvf apache-tomcat-9*tar.gz -C /opt/tomcat --strip-components=1

#update permission
cd /opt/tomcat
sudo chgrp -R tomcat /opt/tomcat
sudo chmod -R g+r conf
sudo chmod g+x conf
sudo chown -R tomcat webapps/ work/ temp/ logs/

#create a systemd service file
cat > /etc/systemd/system/tomcat.service <<-END
[Unit]
Description=Apache Tomcat Web Application Container
After=network.target

[Service]
Type=forking

Environment=JAVA_HOME=/usr/lib/jvm/java-1.11.0-openjdk-amd64
Environment=CATALINA_PID=/opt/tomcat/temp/tomcat.pid
Environment=CATALINA_HOME=/opt/tomcat
Environment=CATALINA_BASE=/opt/tomcat
Environment='CATALINA_OPTS=-Xms512M -Xmx1024M -server -XX:+UseParallelGC'
Environment='JAVA_OPTS=-Djava.awt.headless=true -Djava.security.egd=file:/dev/./urandom'

ExecStart=/opt/tomcat/bin/startup.sh
ExecStop=/opt/tomcat/bin/shutdown.sh

User=tomcat
Group=tomcat
UMask=0007
RestartSec=10
Restart=always

[Install]
WantedBy=multi-user.target
END

sudo systemctl daemon-reload
sudo systemctl start tomcat
#sudo systemctl status tomcat

#adjust firewall
sudo ufw allow 8080
sudo systemctl enable tomcat

#access manager-gui and admin-gui
clear
echo ...:: Tomcat Manager Security ::... 
read -p 'Username: ' tomcatUsername
read -p 'Password: ' tomcatPassword
echo ...................................
sleep 5
clear
sed -i '/<\/tomcat-users>/i <user username="'$tomcatUsername'" password="'$tomcatPassword'" roles="manager-gui,admin-gui"\/>' /opt/tomcat/conf/tomcat-users.xml
sed -i 's/<Valve/<!--<Valve/g' /opt/tomcat/webapps/manager/META-INF/context.xml
sed -i 's/<Manager/--><Manager/g' /opt/tomcat/webapps/manager/META-INF/context.xml
sed -i 's/<Valve/<!--<Valve/g' /opt/tomcat/webapps/host-manager/META-INF/context.xml
sed -i 's/<Manager/--><Manager/g' /opt/tomcat/webapps/host-manager/META-INF/context.xml
sudo systemctl restart tomcat

#update package
sudo apt update

#install default package
sudo apt install mysql-server

#Config MySQL
sudo mysql_secure_installation

#Adjusting User Auth & Privilagr
clear
echo ...:: MySQL ::...
echo Username : root
read -p 'Password : ' mysqlPassword
echo .................
sleep 2
clear
CMD1="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$mysqlPassword';"
CMD2="FLUSH PRIVILEGES;"
CMD3="exit"
sudo mysql -Bse "$CMD1;$CMD2;$CMD3"

#Check MySQL status
#systemctl status mysql.service

#update package
sudo apt update

#install package
sudo apt install phpmyadmin php-mbstring php-gettext

#enable mbstring
sudo phpenmod mbstring

#restart apache
sudo systemctl restart apache2

#Securing phpmyadmin
sed -i '/index.php/a AllowOverride All' /etc/apache2/conf-available/phpmyadmin.conf
sudo systemctl restart apache2

cat > /usr/share/phpmyadmin/.htaccess <<-END
AuthType Basic
AuthName "Restricted Files"
AuthUserFile /etc/phpmyadmin/.htpasswd
Require valid-user
END

clear
echo ...:: PhpMyadmin Security ::...
read -p 'Username: ' phpmyadminUsername
sudo htpasswd -c /etc/phpmyadmin/.htpasswd $phpmyadminUsername
sed -i '/Listen 80/a Listen 99' /etc/apache2/ports.conf
sudo systemctl restart apache2

#setup virtual host
sudo apt-get install apache2
a2enmod proxy
a2enmod proxy_http
systemctl restart apache2
sed -i '/80>/a ProxyPreserveHost On\nProxyPass \/ http:\/\/0.0.0.0:8080\/\nProxyPassReverse \/ http:\/\/0.0.0.0:8080\/\nServerName localhost' /etc/apache2/sites-enabled/000-default.conf
service apache2 restart

#text pelangi
apt-get install ruby -y
gem install lolcat

#setup ssl 
# tutorial by https://bmtechtips.com/install-free-ssl-certificate-digitalocean-apache2.htm
# sudo apt-get update
# sudo add-apt-repository ppa:certbot/certbot
# sudo apt-get update
# sudo apt-get install python-certbot-apache
# sudo apachectl stop
# clear
# read -p 'Your Domain : ' domain
# letsencrypt --authenticator standalone --installer apache -d $domain
# sudo service apache2 start

echo Java Hosting Setup Done....
sleep 2
clear

echo "========================================"| lolcat  
echo "Java Hosting Auto Installer"| lolcat 
echo "----------------------------------------"| lolcat
echo "---------- TOMCAT ----------------------"
echo "Tomcat Manager   : https://$domain/manager/html"| lolcat
echo "Username   : $tomcatUsername"| lolcat
echo "Password   : $tomcatPassword"| lolcat
echo "----------------------------------------"
echo "---------- Phpmyadmin ------------------"
echo "PhpMyadmin : http://$domain:99/phpmyadmin"| lolcat
echo "Username   : root"| lolcat
echo "Password   : $mysqlPassword"| lolcat
echo "----------------------------------------"
echo "========================================"
echo "      Please Reboot VPS  !" | lolcat
echo "========================================"
