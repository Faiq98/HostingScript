#!/bin/sh

myip=`ifconfig | grep -Eo 'inet (addr:)?([0-9]*\.){3}[0-9]*' | grep -Eo '([0-9]*\.){3}[0-9]*' | grep -v '127.0.0' | head -n1`;

echo

if [ $USER != 'root' ]; then
	echo "Sorry, for run the script please using root user"
	exit
fi
echo "Php Hosting Auto Installer..."
sleep 2
clear

echo "Start Auto Installer...."
sleep 2
clear

#update & upgrade package
sudo apt-get update && apt-get upgrade -y 

#install apache
sudo apt install apache2 -y

#adjust the firewall
sudo ufw allow in "Apache Full"

#install default package
sudo apt install mysql-server -y

#Config MySQL
sudo mysql_secure_installation

#Adjusting User Auth & Privilagr
clear
echo "...:: MySQL ::..."
echo "Username : root"
read -p 'Password : ' mysqlPassword
echo "................."
sleep 2
clear
CMD1="ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '$mysqlPassword';"
CMD2="FLUSH PRIVILEGES;"
CMD3="SET GLOBAL sql_mode=(SELECT REPLACE(@@sql_mode,'ONLY_FULL_GROUP_BY',''));"
CMD4="exit;"
sudo mysql -Bse "$CMD1;$CMD2;$CMD3;$CMD4"

#Check MySQL status
#systemctl status mysql.service

#update package
sudo apt update

#install php
sudo apt install php libapache2-mod-php php-mysql -y

#change index.php location
sed -i 's/\<index.php\>//g;s/index.html/index.php index.html/g' /etc/apache2/mods-enabled/dir.conf

sudo systemctl restart apache2

#install php-cli
sudo apt install php-cli

#Setup virtual host
#create domain directory
echo "Create directory for your file"
read -p 'File name : ' fileName
sudo mkdir /var/www/$fileName

#asign ownership
sudo chown -R $USER:$USER /var/www/$fileName

#give permission
sudo chmod -R 777 /var/www/$fileName

#create alias to your file dir in 1st line
sed -i "1s/^/alias "$fileName"='cd \/var\/www\/"$fileName"'\n/" .bashrc
cd
source .bashrc

#config own domain directory
read -p 'Do you has your own domain ? (y/n): ' hasDomain
if test $hasDomain = 'y' 
then
read -p 'Domain name: ' domainName
read -p 'Index.php directory: ' dir
cat > /etc/apache2/sites-available/$fileName.conf <<-END
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName $domainName
    ServerAlias www.$domainName
    DocumentRoot /var/www/$fileName/$dir
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
END
else
read -p 'Index.php directory: ' dir
cat > /etc/apache2/sites-available/$fileName.conf <<-END
<VirtualHost *:80>
    ServerAdmin webmaster@localhost
    ServerName $myip
    DocumentRoot /var/www/$fileName/$dir
    ErrorLog \${APACHE_LOG_DIR}/error.log
    CustomLog \${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
END
fi

#enable .conf file 
sudo a2ensite $fileName.conf

#disable default .conf
sudo a2dissite 000-default.conf

#restart apache
sudo systemctl restart apache2

#install phpMyAdmin
sudo apt update
clear

echo "....:::  ! Important  :::...."
echo "Before continue please make sure you understand the step."
echo "1. Choose apache2 as web server"
echo "2. Use SPACE button to select."
echo "3. Select YES for configure db with dbconfig-common"
printf 'press [ENTER] to continue...'
read _
sudo apt install phpmyadmin php-mbstring php-gettext -y

#enable mbstring
sudo phpenmod mbstring

#restart apache
sudo systemctl restart apache2

#Securing phpmyadmin
sed -i '/index.php/a AllowOverride All' /etc/apache2/conf-available/phpmyadmin.conf

#find and replace between 2 patern
sed -i '/<Directory \/var\/www\/>/,/<\/Directory>/ s/AllowOverride None/AllowOverride All/' /etc/apache2/apache2.conf

#enable module rewrite & restart
sudo a2enmod rewrite
sudo systemctl restart apache2

cat > /usr/share/phpmyadmin/.htaccess <<-END
AuthType Basic
AuthName "Restricted Files"
AuthUserFile /etc/phpmyadmin/.htpasswd
Require valid-user
END

clear
echo "...:: PhpMyadmin Security ::..."
read -p 'Username: ' phpmyadminUsername
sudo htpasswd -c /etc/phpmyadmin/.htpasswd $phpmyadminUsername
sudo systemctl restart apache2

#text pelangi
apt-get install ruby -y
gem install lolcat

#setup ssl 
# tutorial by https://bmtechtips.com/install-free-ssl-certificate-digitalocean-apache2.htm
if test $hasDomain = 'y' 
then
sudo apt-get update
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install python-certbot-apache -y
sudo apachectl stop
clear
letsencrypt --authenticator standalone --installer apache -d $domainName
sudo service apache2 start
fi
sudo service apache2 start

#set webhook
clear
read -p "Want to set Github Webhooks ? (y/n): " webhook
if [ $webhook = 'y' ]; then
#create dir
cd
sudo apt-get install nodejs
sudo mkdir NodeWebhook

#create webhook script
read -p 'Secret: ' secret

cat > NodeWebhook/webhook.js <<-END
const secret = "$secret";
const repo = "/var/www/$fileName/$dir";

const http = require('http');
const crypto = require('crypto');
const exec = require('child_process').exec;

http.createServer(function (req, res) {
    req.on('data', function(chunk) {
        let sig = "sha1=" + crypto.createHmac('sha1', secret).update(chunk.toString()).digest('hex');

        if (req.headers['x-hub-signature'] == sig) {
            exec('cd ' + repo + ' && git pull --no-edit');
        }
    });

    res.end();
}).listen(8080);
END

#allow traffic on port 8080
sudo ufw allow 8080/tcp

#install webhook as systemd service
cat > /etc/systemd/system/webhook.service <<-END
[Unit]
Description=Github webhook
After=network.target

[Service]
Environment=NODE_PORT=8080
Type=simple
User=root
ExecStart=/usr/bin/nodejs /root/NodeWebhook/webhook.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

#enable the service 
sudo systemctl enable webhook.service

#start service
sudo systemctl start webhook
fi

#create ssh keygen
cd .ssh
ssh-keygen

echo Php Hosting Setup Done....
sleep 2
clear

echo "========================================"| lolcat  
echo "Php Hosting Auto Installer"| lolcat 
echo "----------------------------------------"| lolcat
echo "---------- Instruction -----------------"
echo "Place your index.php file in /var/www/$fileName" | lolcat
echo "Type [$fileName] to go to your file" | lolcat
echo
echo "To change document root path" | lolcat
echo "sudo nano /etc/apache2/sites-available/$fileName.conf" | lolcat
echo "----------------------------------------"
if test $hasDomain = 'y'
then
echo "---------- Phpmyadmin ------------------"
echo "PhpMyadmin : http://$domainName/phpmyadmin"| lolcat
echo "Username   : $phpmyadminUsername"| lolcat
echo "Password   : $mysqlPassword"| lolcat
echo "----------------------------------------"
else
echo "---------- Phpmyadmin ------------------"
echo "PhpMyadmin : http://$myip/phpmyadmin"| lolcat
echo "Username   : $phpmyadminUsername"| lolcat
echo "Password   : $mysqlPassword"| lolcat
echo "----------------------------------------"
fi
echo "---------- Webhook ------------------"
echo "PhpMyadmin : http://$myip/phpmyadmin"| lolcat
echo "Secret   : $secret"| lolcat
echo "Deploy Key   : "| lolcat
echo "----------------------------------------"
cd
cat .ssh/id_rsa.pub
echo "----------------------------------------"
echo "----------------------------------------"
echo "========================================"
echo "      Please Reboot VPS  !" | lolcat
echo "========================================"
