#!/bin/bash

echo "Provisioning virtual machine..."

apt-get update -y > /dev/null
apt-get install nginx -y

echo "Configuring Nginx"
cp /vagrant/nginx.config /etc/nginx/sites-available/nginx_vhost
ln -s /etc/nginx/sites-available/nginx_vhost /etc/nginx/sites-enabled/
rm -rf /etc/nginx/sites-available/default
service nginx restart