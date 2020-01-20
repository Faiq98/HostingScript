#!/bin/sh

#update package
sudo apt update

#install JDK package
sudo apt install default-jdk

#create tomcat group
sudo groupadd tomcat

#create new tomcat user
sudo useradd -s /bin/false -g tomcat -d /opt/tomcat tomcat

#change directory to tmp
cd /tmp

#download tomcat
curl -O https://www-eu.apache.org/dist/tomcat/tomcat-9/v9.0.30/bin/apache-tomcat-9.0.30.tar.gz

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
sed -i 's|\(<\/tomcat-users>\)|<user username="admin" password="password" roles="manager-gui,admin-gui"\/>\n<\/tomcat-users>|g' /opt/tomcat/conf/tomcat-users.xml
sed -i 's/<Valve/<!--<Valve/g' /opt/tomcat/webapps/manager/META-INF/context.xml
sed -i 's/<Manager/--><Manager/g' /opt/tomcat/webapps/manager/META-INF/context.xml
sed -i 's/<Valve/<!--<Valve/g' /opt/tomcat/webapps/host-manager/META-INF/context.xml
sed -i 's/<Manager/--><Manager/g' /opt/tomcat/webapps/host-manager/META-INF/context.xml
sudo systemctl restart tomcat