#!/bin/bash

set -e  # Exit immediately if a command fails

# Detect the OS type
if [ -f /etc/os-release ]; then
    . /etc/os-release
    OS=$ID
else
    echo "Cannot detect OS. Exiting."
    exit 1
fi

# Install Docker based on the OS
echo "Installing Docker on $OS..."

if [[ "$OS" == "ubuntu" || "$OS" == "debian" ]]; then
    sudo apt update
    sudo apt install -y apt-transport-https ca-certificates curl software-properties-common
    curl -fsSL https://download.docker.com/linux/$OS/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/$OS $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt update
    sudo apt install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
elif [[ "$OS" == "centos" || "$OS" == "rhel" || "$OS" == "fedora" ]]; then
    sudo dnf install -y dnf-plugins-core
    sudo dnf config-manager --add-repo https://download.docker.com/linux/$OS/docker-ce.repo
    sudo dnf install -y docker-ce docker-ce-cli containerd.io docker-compose-plugin
    sudo systemctl enable --now docker
else
    echo "Unsupported OS: $OS. Please install Docker manually."
    exit 1
fi

# Add user to docker group
if ! groups | grep -q "\bdocker\b"; then
    echo "Adding user $USER to the docker group..."
    sudo groupadd -f docker
    sudo usermod -aG docker $USER
    echo "User added to the docker group."
else
    echo "User $USER is already in the docker group."
fi

# Restart Docker service
sudo systemctl restart docker

# Verify installation
echo "Verifying Docker installation..."
if ! docker --version &>/dev/null; then
    echo "Docker installation failed. Please check logs and try again."
    exit 1
fi

echo "Verifying Docker Compose installation..."
if ! docker compose version &>/dev/null; then
    echo "Docker Compose installation failed. Please check logs and try again."
    exit 1
fi

echo "Docker and Docker Compose are installed successfully."

# Automatic reboot after installation
echo "Rebooting system in 5 seconds to apply changes..."
sleep 5
sudo reboot now
