#!/bin/sh

sudo apt-get update
sudo add-apt-repository ppa:certbot/certbot
sudo apt-get update
sudo apt-get install python-certbot-apache
sudo apachectl stop
clear

read -p 'Domain : ' domain
letsencrypt --authenticator standalone --installer apache -d $domain

sudo service apache2 start