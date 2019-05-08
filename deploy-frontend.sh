#! /bin/bash

# A simple script to automatically deploy the Yummy Recipes
# REACT Frontend App to an Amazon EC2 centos 16.04 instance

function initialize_worker() {
    printf "***************************************************\n\t\t
    Setting up host
    \n***************************************************\n"
    # Update packages
    echo ======= Updating packages ========
    sudo yum update

    # Export language locale settings
    echo ======= Exporting language locale settings =======
    export LC_ALL=en_US.UTF-8
    export LANG=en_US.UTF-8

    # Install NodeJS and NPM
    echo ======= Installing NodeJS =======
    cd ~
    sudo curl -sL https://deb.nodesource.com/setup_8.x -o nodesource_setup.sh
    cat nodesource_setup.sh
    sudo bash nodesource_setup.sh
    sudo yum install -y nodejs
    node --version # Ensure NodeJS is installed
    npm --version # Ensure Node Package Manager CLI tool is installed as well
}

function clone_app_repository() {
    printf "***************************************************\n\t\t
    Fetching App
    \n***************************************************\n"
    # Clone and access project directory
    echo ======== Cloning and accessing project directory ========
    if [[ -d ~/yummy-react ]]; then
        sudo rm -rf ~/yummy-react
    fi
    git clone -b develop https://github.com/indungu/yummy-react.git ~/yummy-react
    cd ~/yummy-react/
}

function setup_app() {
    printf "***************************************************\n
        Installing App dependencies and Env Variables
    \n***************************************************\n"
    # Install required packages
    echo ======= Installing required packages ========
    sudo npm install --global yarn
    sudo yarn install
    echo ======= Creating production build ========
    sudo yarn build production
}

# Install and configure nginx
function setup_nginx() {
    printf "***************************************************\n\t\t
    Setting up nginx
    \n***************************************************\n"
    echo ======= Installing nginx =======
    sudo yum install -y nginx

    # Configure nginx routing
    echo ======= Configuring nginx =======
    echo ======= Removing default config =======
    sudo rm -f /etc/nginx/sites-available/*
    sudo rm -f /etc/nginx/sites-enabled/*
    if [[ /etc/nginx/sites-available/yummyreact ]]; then
        sudo rm -f /etc/nginx/sites-available/yummyreact
        sudo rm -f /etc/nginx/sites-enabled/yummyreact
    fi
    echo ======= Replace config file =======
    sudo bash -c 'cat > /etc/nginx/sites-available/yummyreact << EOF
    server {
            listen 80 default_server;
            listen [::]:80 default_server;

            server_name _;

            location / {
                    # reverse proxy and serve the app
                    # running on the localhost:3000
                    proxy_pass http://127.0.0.1:3000/;
                    proxy_set_header HOST \$host;
                    proxy_set_header X-Forwarded-Proto \$scheme;
                    proxy_set_header X-Real-IP \$remote_addr;
                    proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
            }
    }'

    echo ======= Create a symbolic link of the file to sites-enabled =======
    sudo ln -s /etc/nginx/sites-available/yummyreact /etc/nginx/sites-enabled/

    # Ensure nginx server is running
    echo ====== Checking nginx server status ========
    sudo systemctl restart nginx
    sudo nginx -t
}

# Add a launch script
create_launch_script () {
    printf 'printf "***************************************************\n\t\t
    Createing a Launch script
    \n***************************************************\n'

    sudo bash -c 'cat > ~/launch.sh << EOF
    #!/bin/bash
    cd ~/yummy-react
    yarn start
    '
    sudo chmod +x ~/launch.sh
}

configure_startup_service () {
    printf '***************************************************\n\t\t
    Configuring startup service
    \n***************************************************\n'

    sudo bash -c 'cat > /etc/systemd/system/yummy.service <<EOF
    [Unit]
    Description=yummy-react launch service
    After=network.target
    [Service]
    User=centos
    ExecStart=/bin/bash ~/launch.sh
    Restart=always
    [Install]
    WantedBy=multi-user.target
    '

    sudo chmod 664 /etc/systemd/system/yummy.service
    sudo systemctl daemon-reload
    sudo systemctl enable yummy.service
    sudo systemctl start yummy.service

}
# Serve the web app through gunicorn
# function serve_app() {
#     printf "***************************************************\n\t\tServing the App \n***************************************************\n"
#     yarn start
# }

######################################################################
########################      RUNTIME       ##########################
######################################################################

initialize_worker
clone_app_repository
setup_app
setup_nginx
create_launch_script
configure_startup_service
