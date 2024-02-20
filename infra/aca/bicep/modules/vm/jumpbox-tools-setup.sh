#!/bin/bash

# Script Definition
logpath=/var/log/deploymentscriptlog

# Upgrading Linux Distribution
echo "#############################" >> $logpath
echo "Upgrading Linux Distribution" >> $logpath
echo "#############################" >> $logpath
sudo apt-get update >> $logpath
sudo apt-get -y upgrade >> $logpath
echo " " >> $logpath

# Install Azure CLI
echo "#############################" >> $logpath
echo "Installing Azure CLI" >> $logpath
echo "#############################" >> $logpath
curl -sL https://aka.ms/InstallAzureCLIDeb | sudo bash >> $logpath

# Install Azure Developer CLI
echo "#############################" >> $logpath
echo "Installing Azure Developer CLI" >> $logpath
echo "#############################" >> $logpath
curl -fsSL https://aka.ms/install-azd.sh | bash >> $logpath



# Install Docker
echo "#############################" >> $logpath
echo "Installing Docker" >> $logpath
echo "#############################" >> $logpath
wget -qO- https://get.docker.com/ | sh >> $logpath
sudo usermod -aG docker azureuser
echo " " >> $logpath


# Install Microsoft OpenJDK 17
echo "#############################" >> $logpath
echo "Installing Microsoft OpenJDK17" >> $logpath
echo "#############################" >> $logpath
ubuntu_release=`lsb_release -rs`
wget https://packages.microsoft.com/config/ubuntu/${ubuntu_release}/packages-microsoft-prod.deb -O packages-microsoft-prod.deb >> $logpath
sudo dpkg -i packages-microsoft-prod.deb >> $logpath
rm packages-microsoft-prod.deb
sudo apt-get install apt-transport-https >> $logpath
sudo apt-get update >> $logpath
sudo apt-get install msopenjdk-17 -y >> $logpath

# Install Maven
echo "#############################" >> $logpath
echo "Installing Maven 3.8.8" >> $logpath
echo "#############################" >> $logpath
wget https://dlcdn.apache.org/maven/maven-3/3.8.8/binaries/apache-maven-3.8.8-bin.tar.gz -P /tmp >> $logpath
sudo tar xf /tmp/apache-maven-*.tar.gz -C /opt
sudo ln -s /opt/apache-maven-3.8.8 /opt/maven -s

echo "export JAVA_HOME=/usr/lib/jvm/msopenjdk-17-amd64" >> ~/.bashrc
echo "export M2_HOME=/opt/maven" >> ~/.bashrc
echo "export MAVEN_HOME=/opt/maven" >> ~/.bashrc
echo "export PATH=${M2_HOME}/bin:${PATH}" >> ~/.bashrc

source ~/.bashrc