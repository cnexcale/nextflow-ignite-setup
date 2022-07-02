#!/bin/bash

# taken from https://docs.docker.com/engine/install/ubuntu/#install-using-the-repository

# install dependencies
sudo apt-get update
sudo apt-get install -y \
              ca-certificates \
              curl \
              gnupg \
              lsb-release

# add docker gpg key
sudo mkdir -p /etc/apt/keyrings
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /etc/apt/keyrings/docker.gpg

# setup repository
echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null

# install docker
sudo apt-get update
sudo apt-get install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin

# add current user to docker group
sudo usermod -aG docker $USER
