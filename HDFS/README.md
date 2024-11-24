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

## Automation script (On Master only)
Use the below script to setup and start the HDFS

1. Make the `hdfs-setup.sh` script executable
```bash
    chmod +x hdfs-setup.sh
```

2. Run the script
```bash
    ./hdfs-setup.sh <master-ip> <worker-1-ip> <worker-2-ip> <worker-3-ip>
```

3. Source the `bashrc`
```bash
    source ~/.bashrc
```

4. Format the NameNode:
```bash
   hdfs namenode -format
```

5. Start the HDFS services:
```bash
   start-dfs.sh
```

6. Verify the setup:
```bash
   hdfs dfs -mkdir /test/
   hdfs dfs -put testfile.txt /test/
   hdfs dfs -ls /
   hdfs dfs -ls /test/
```

7. Stop the HDFS services:
```bash
    stop-dfs.sh
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
```

---

## Testing HDFS with FIO (Flexible IO Tester) (Only on Master)

### Prerequisites
```bash
sudo apt install build-essential
```

### Installing FIO
1. Clone the FIO repository:
   ```bash
   git clone https://github.com/axboe/fio.git
   ```

2. Configure the environment:
   ```bash
   # The directory that contains 'libhdfs.a'.
   export FIO_LIBHDFS_LIB="/usr/local/hadoop/lib/native"
   
   # Ensure 'hdfs.h' is included in this directory (can be found in Hadoop source code).
   export FIO_LIBHDFS_INCLUDE="/usr/local/hadoop/include"
   
   # Set the Hadoop classpath.
   export CLASSPATH=$(hadoop classpath)
   ```

3. Generate configurations for `make` inside `fio` directory:
   ```bash
   ./configure --enable-libhdfs
   ```

4. Build and install:
   ```bash
   make
   sudo make install
   ```

---

### Testing HDFS with FIO
1. Create a test directory and upload a file to HDFS:
   ```bash
   hdfs dfs -mkdir /fio/
   hdfs dfs -put testfile.txt /fio/
   ```

2. Navigate to the `fio` directory and run the following tests:

#### Sequential Write Test
```bash
fio --name=sequential_write_test \
    --rw=write \
    --bs=4k \
    --size=1G \
    --numjobs=1 \
    --runtime=60 \
    --ioengine=libhdfs \
    --namenode=<master-ip> \
    --hostname=<master-ip> \
    --port=9000 \
    --hdfsdirectory=/fio/ \
    --chunk_size=1G \
    --group_reporting \
    --filename=testfile.txt
```

#### Sequential Read Test
```bash
fio --name=sequential_read_test \
    --rw=read \
    --bs=4k \
    --size=1G \
    --numjobs=1 \
    --runtime=60 \
    --ioengine=libhdfs \
    --namenode=<master-ip> \
    --hostname=<master-ip> \
    --port=9000 \
    --hdfsdirectory=/fio/ \
    --chunk_size=1G \
    --group_reporting
```

#### Random Read Test
```bash
fio --name=random_read_test \
    --rw=randread \
    --bs=4k \
    --size=1G \
    --numjobs=1 \
    --runtime=60 \
    --ioengine=libhdfs \
    --namenode=<master-ip> \
    --hostname=<master-ip> \
    --port=9000 \
    --hdfsdirectory=/fio/ \
    --chunk_size=1G \
    --group_reporting
```

---

### Note on Random Writes
- **Random writes are not supported by HDFS with FIO**:
  - In HDFS, files once created cannot be modified, so random writes are not possible.
  - To imitate this, the `libhdfs` engine expects a set of small files to be created over HDFS and randomly picks a file based on the offset generated by the FIO backend.
  - Use the `rw=write` option to create such files (see the example job file in FIO documentation).

- Ensure necessary environment variables are set to work with HDFS/libhdfs properly.
- Each job uses its own connection to HDFS.

For more details, refer to the [FIO Documentation](https://fio.readthedocs.io/en/latest/fio_doc.html).
