#!/bin/bash

# Check if all required arguments are provided
if [ "$#" -ne 4 ]; then
    echo "Usage: $0 <master-ip> <worker-1-ip> <worker-2-ip> <worker-3-ip>"
    exit 1
fi

MASTER_IP=$1
WORKER1_IP=$2
WORKER2_IP=$3
WORKER3_IP=$4
HADOOP_VERSION="3.4.0"
HADOOP_URL="https://dlcdn.apache.org/hadoop/common/hadoop-${HADOOP_VERSION}/hadoop-${HADOOP_VERSION}.tar.gz"
WORKER_IPS=($WORKER1_IP $WORKER2_IP $WORKER3_IP)

# Function to create configuration files
create_config_files() {
    # Create core-site.xml
    sudo tee /usr/local/hadoop/etc/hadoop/core-site.xml > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>fs.defaultFS</name>
        <value>hdfs://${MASTER_IP}:9000</value>
    </property>
</configuration>
EOF

    # Create hdfs-site.xml
    sudo tee /usr/local/hadoop/etc/hadoop/hdfs-site.xml > /dev/null <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<?xml-stylesheet type="text/xsl" href="configuration.xsl"?>
<configuration>
    <property>
        <name>dfs.replication</name>
        <value>3</value>
    </property>
    <property>
        <name>dfs.namenode.name.dir</name>
        <value>file:///usr/local/hadoop/hdfs/namenode</value>
    </property>
    <property>
        <name>dfs.datanode.data.dir</name>
        <value>file:///usr/local/hadoop/hdfs/datanode</value>
    </property>
</configuration>
EOF

    # Create workers file
    sudo tee /usr/local/hadoop/etc/hadoop/workers > /dev/null <<EOF
${MASTER_IP}
${WORKER1_IP}
${WORKER2_IP}
${WORKER3_IP}
EOF

    # Update hadoop-env.sh with JAVA_HOME
    sudo tee -a /usr/local/hadoop/etc/hadoop/hadoop-env.sh > /dev/null <<EOF
export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
EOF
    # Set proper permissions
    sudo chown -R $USER:$USER /usr/local/hadoop/
    sudo chown -R $USER:$USER /usr/local/hadoop/etc/hadoop/
}

echo "=== Starting HDFS Cluster Setup ==="

# Install Java and create directories on master
echo "Installing Java on master node..."
sudo apt update
sudo apt install -y openjdk-8-jdk

# Download Hadoop on master
echo "Downloading Hadoop..."
wget -q ${HADOOP_URL}
sudo tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /usr/local/
sudo mv /usr/local/hadoop-${HADOOP_VERSION} /usr/local/hadoop

# Create necessary directories
sudo mkdir -p /usr/local/hadoop/hdfs/namenode
sudo mkdir -p /usr/local/hadoop/hdfs/datanode

# Set environment variables on master
echo "Setting up environment variables..."
echo "export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre" >> ~/.bashrc
echo "export HADOOP_HOME=/usr/local/hadoop" >> ~/.bashrc
echo "export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin" >> ~/.bashrc
source ~/.bashrc

# Create configuration files
echo "Creating configuration files..."
cd /usr/local/hadoop/etc/hadoop
create_config_files
cd

# Setup worker nodes
for worker_ip in "${WORKER_IPS[@]}"; do
    echo "Setting up worker node: ${worker_ip}"
    
    # Install Java on worker
    ssh ${worker_ip} "sudo apt update && sudo apt install -y openjdk-8-jdk"
    
    # Copy Hadoop to worker
    echo "Copying Hadoop to worker ${worker_ip}..."
    scp hadoop-${HADOOP_VERSION}.tar.gz ${worker_ip}:~/
    ssh ${worker_ip} "sudo tar -xzf hadoop-${HADOOP_VERSION}.tar.gz -C /usr/local/ && \
                      sudo mv /usr/local/hadoop-${HADOOP_VERSION} /usr/local/hadoop && \
                      sudo mkdir -p /usr/local/hadoop/hdfs/datanode && \
                      sudo mkdir -p /usr/local/hadoop/logs && \
                      sudo chown -R \$USER:\$USER /usr/local/hadoop"
    
    # Create config directory with correct permissions
    ssh ${worker_ip} "sudo mkdir -p /usr/local/hadoop/etc/hadoop && \
                      sudo chown -R \$USER:\$USER /usr/local/hadoop/etc/hadoop"
    
    # Copy configuration files to worker
    echo "Copying configuration files to worker ${worker_ip}..."
    scp /usr/local/hadoop/etc/hadoop/core-site.xml ${worker_ip}:/usr/local/hadoop/etc/hadoop/
    scp /usr/local/hadoop/etc/hadoop/hdfs-site.xml ${worker_ip}:/usr/local/hadoop/etc/hadoop/
    scp /usr/local/hadoop/etc/hadoop/hadoop-env.sh ${worker_ip}:/usr/local/hadoop/etc/hadoop/
    
    # Set environment variables on worker
    ssh ${worker_ip} "echo 'export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre' >> ~/.bashrc && \
                      echo 'export HADOOP_HOME=/usr/local/hadoop' >> ~/.bashrc && \
                      echo 'export PATH=\$PATH:\$HADOOP_HOME/bin:\$HADOOP_HOME/sbin' >> ~/.bashrc && \
                      source ~/.bashrc"
done

mkdir -p /usr/local/hadoop/logs

# Format namenode and start HDFS
echo "Formatting namenode..."
hdfs namenode -format

echo "Starting HDFS services..."
start-dfs.sh

echo "=== HDFS Cluster Setup Complete ==="
