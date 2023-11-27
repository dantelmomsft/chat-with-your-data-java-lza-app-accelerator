# Install Java JDK 17
sudo apt update
sudo apt install -y openjdk-17-jdk

# Install Maven 3.9.5
wget https://dlcdn.apache.org/maven/maven-3/3.9.5/binaries/apache-maven-3.9.5-bin.tar.gz
tar -xf apache-maven-3.9.5-bin.tar.gz
sudo mv apache-maven-3.9.5 /opt/maven
sudo ln -s /opt/maven/bin/mvn /usr/local/bin/mvn

echo "Java JDK 17 and Maven 3.9.5 installed successfully!"