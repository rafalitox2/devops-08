#! /bin/bash

# This is a simple script that uses Certbot to install
# SSL certificates when serving web applications using
# nginx

# Setup host

function setup_host() {
    printf "***************************************************\n\t\t Setting up host \n***************************************************\n"
    echo ================ installing yum-utils ================
    yum -y install yum-utils
    echo ================ installing yum-utils ================
    yum-config-manager --enable rhui-eu-west-1a-rhel-server-extras rhui-eu-west-1a-rhel-server-optional

}

function install_certbot() {
    printf "***************************************************\n\t\t Installing Certbot \n***************************************************\n"
    sudo yum install certbot python3-certbot-nginx
}

function install_certificate() {
    printf "***************************************************\n\tInstalling SSL Certificate \n***************************************************\n"
    echo "====== Ensuring that nginx is running ======="
    sudo service nginx status
    echo "======= Installing SSL for nginx ======="
    sudo certbot --nginx
}

######################################################################
########################      RUNTIME       ##########################
######################################################################
setup_host
install_certbot
install_certificate
