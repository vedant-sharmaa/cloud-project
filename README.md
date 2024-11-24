# Setting up HDFS on 4 Nodes

## Prerequisites
1. **4 VMs(nodes)**: 1 Master and 3 Workers.
2. **Passwordless SSH** setup between nodes.

### Setting up Passwordless SSH:
1. Run the following command on each node to generate SSH keys:
   ```bash
   ssh-keygen -t rsa -b 4096
   ```
   This will generate `id_rsa` and `id_rsa.pub` in the `~/.ssh/` directory.

2. Open `id_rsa.pub` on each node and copy its contents.

3. Paste the contents into the `~/.ssh/authorized_keys` file on all nodes (create the file if it does not exist).

4. Verify SSH connectivity:
   ```bash
   ssh <other-node-ip>
   ```

---

## Automation script
Run the below script to run and setup the HDFS

1. Make the `hdfs-setup.sh` script executable
```bash
    chmod +x hdfs-setup.sh
```

2. Run the script
```bash
    ./hdfs-setup.sh <master-ip> <worker-1-ip> <worker-2-ip> <worker-3-ip>
```

(Note: The above are private IPs of the VMs.)

## Or Run the following commands on all nodes (Manual steps)

### Installing Java
```bash
sudo apt update
sudo apt install -y openjdk-8-jdk
java -version  # Verify Java installation
```

---

### Downloading and Installing Hadoop
1. Download Hadoop:
   ```bash
   wget https://dlcdn.apache.org/hadoop/common/hadoop-3.4.0/hadoop-3.4.0.tar.gz
   ```

2. Extract and move Hadoop to `/usr/local/`:
   ```bash
   sudo tar -xvzf hadoop-3.4.0.tar.gz -C /usr/local/
   sudo mv /usr/local/hadoop-3.4.0 /usr/local/hadoop
   ```

---

### Setting Environment Variables
1. Edit `~/.bashrc`:
   ```bash
   vim ~/.bashrc
   ```

2. Add the following lines:
   ```bash
   export JAVA_HOME=/usr/lib/jvm/java-8-openjdk-amd64/jre
   export HADOOP_HOME=/usr/local/hadoop
   export PATH=$PATH:$HADOOP_HOME/bin:$HADOOP_HOME/sbin
   ```

3. Apply the changes:
   ```bash
   source ~/.bashrc
   ```

---

### Configuring Hadoop
Navigate to the Hadoop configuration directory:
```bash
cd /usr/local/hadoop/etc/hadoop
```

#### Update `core-site.xml`:
Edit `core-site.xml`:
```bash
vim core-site.xml
```
Add the following:
```xml
<configuration>
  <property>
    <name>fs.defaultFS</name>
    <value>hdfs://<namenode-ip>:<port-number></value>
  </property>
</configuration>
```

#### Update `hdfs-site.xml`:
Edit `hdfs-site.xml`:
```bash
vim hdfs-site.xml
```
Add the following:
```xml
<configuration>
  <property>
    <name>dfs.replication</name>
    <value>3</value>  <!-- Number of replicas across DataNodes -->
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
```

---

## Master Node Only

### Update workers file 
Edit `workers` in `/usr/local/hadoop/etc/hadoop`:
```bash
vim workers
```
Add the following:
```xml
master-ip
worker-1-ip
worker-2-ip
worker-3-ip
```

### Starting HDFS
1. Create logs directory:
    ```bash
    mkdir -p /usr/local/hadoop/logs
    ```

2. Format the NameNode:
   ```bash
   hdfs namenode -format
   ```

3. Start the HDFS services:
   ```bash
   start-dfs.sh
   ```

4. Verify the setup:
   ```bash
   hdfs dfs -mkdir /test/
   hdfs dfs -put testfile.txt /test/
   hdfs dfs -ls /
   hdfs dfs -ls /test/
   ```

---

### Stopping HDFS
Stop the HDFS services:
```bash
stop-dfs.sh
