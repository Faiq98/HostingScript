#!/bin/sh

#create dir
cd
sudo mkdir NodeWebhook

#create webhook script
read -p 'Secret: ' secret
read -p 'Repo dir: ' repo

cat > NodeWebhook/webhook.js <<-END
const secret = "$secret";
const repo = "$repo";

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
ExecStart=/usr/bin/nodejs /root/NodeWebhooks/webhook.js
Restart=on-failure

[Install]
WantedBy=multi-user.target
END

#enable the service 
sudo systemctl enable webhook.service

#start service
sudo systemctl start webhook