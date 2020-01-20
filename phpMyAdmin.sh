#!/bin/sh

#update package
sudo apt update

#install package
sudo apt install phpmyadmin php-mbstring php-gettext

#enable mbstring
sudo phpenmod mbstring

#restart apache
sudo systemctl restart apache2

#Securing phpmyadmin
sudo nano /etc/apache2/conf-available/phpmyadmin.conf
sed -i '/index.php/a AllowOverride All' /etc/apache2/conf-available/phpmyadmin.conf
sudo systemctl restart apache2

cat > /usr/share/phpmyadmin/.htaccess <<-END
AuthType Basic
AuthName "Restricted Files"
AuthUserFile /etc/phpmyadmin/.htpasswd
Require valid-user
END

sudo htpasswd -c /etc/phpmyadmin/.htpasswd username
sed -i '/Listen 80/a Listen 99' /etc/apache2/ports.conf

#setup virtual host
sudo apt-get install apache2
a2enmod proxy
a2enmod proxy_http
systemctl restart apache2
sed -i '/80>/a ProxyPreserveHost On\nProxyPass \/ http:\/\/0.0.0.0:8080\/\nProxyPassReverse \/ http:\/\/0.0.0.0:8080\/\nServerName localhost' /etc/apache2/sites-enabled/000-default.conf
service apache2 restart
