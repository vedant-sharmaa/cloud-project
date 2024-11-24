# Setting up Gluster-FS on 4 VMs
We use 4 VMs (3 Servers and 1 Client) for this project.

## Follow the below steps on all the VMs

### Update and Upgrade
Make sure to first update and upgrade all the machines. 
```
sudo apt-get update
sudo apt-get upgrade
```
### Naming the Machines
We name the machines `gluster1`, `gluster2`, `gluster3` and `gluster4`.

1. On the first server, set the hostname to gluster1
```
sudo hostnamectl set-hostname gluster1
```

2. On the second server, set the hostname to gluster2
```
sudo hostnamectl set-hostname gluster2
```

3. On the third server, set the hostname to gluster3
```
sudo hostnamectl set-hostname gluster3
```

4. On the fourth server, set the hostname to gluster4
```
sudo hostnamectl set-hostname gluster4
```

### Add Hosts
We need to map the addresses in the `/etc/hosts` file. Open the file with the following command
```
sudo nano /etc/hosts
```
Add the following lines to the end of the file on each of the machines.
```
<IP of Server1> gluster1
<IP of Server2> gluster2
<IP of Server3> gluster3
<IP of Client> gluster4
```

## Server Setup
We need to first install `glusterfs-server` on all three of the Servers. This can be done with the command:
```
sudo apt-get install glusterfs-server -y
```
After the installation completes, start and enable GlusterFS on each server
```
sudo systemctl start glusterd
sudo systemctl enable glusterd
```

### Configuring the Cluster (Only on server 1)
Create a trusted pool on `gluster1` with the commands:
```
sudo gluster peer probe gluster2
```
```
sudo gluster peer probe gluster3
```
Verify the status of the cluster with the command:
```
sudo gluster peer status
```


### Creating a Distributed Volume
Create a new directory on `gluster1`, `gluster2` and `gluster3` for GlusterFS
```
sudo mkdir -p /glusterfs/distributed
```
### Only on server 1 (gluster1)
We now create the volume `v01` that will replicate on `gluster1`, `gluster2` and `gluster3`
```
sudo gluster volume create v01 replica 3 transport tcp \
    gluster1:/glusterfs/distributed \
    gluster2:/glusterfs/distributed \
    gluster3:/glusterfs/distributed
```
Once the creation of the volume succeeds, start the volume with the command:
```
sudo gluster volume start v01
```
The creation of the volume can be verified as
```
sudo gluster volume info v01
```

## Setting Up the Client
We need to install `glusterfs-client` on the Client (`gluster4`)
```
sudo apt install glusterfs-client -y
```
Create a new directory on `gluster4`
```
sudo mkdir -p /mnt/glusterfs
```
We now mount the distributed file system with the command
```
sudo mount -t glusterfs gluster1:/v01 /mnt/glusterfs/
```
### Mount File System at Boot (Optional)
If you want that the distributed file system is mounted at boot then the `fstab` file needs to be edited. Open the file with the command:
```
sudo nano /etc/fstab
```
Add the following line to the bottom of the file
```
gluster1:/v01 /mnt/glusterfs glusterfs defaults,_netdev 0 0
```

### Testing the Filesystem
With the setup completed we now have to ensure that our file system is functioning as expected.
On `gluster1` issue the command
```
sudo mount -t glusterfs gluster1:/v01 /mnt
```
On `gluster2` issue the command
```
sudo mount -t glusterfs gluster2:/v01 /mnt
```
On `gluster3` issue the command
```
sudo mount -t glusterfs gluster3:/v01 /mnt
```
Create a new file in `gluster4` using the command:
```
sudo touch /mnt/glusterfs/thenewstack
```
Check that the new file appears on `gluster1`, `gluster2` and `gluster3` using
```
ls /mnt
```
You should see the file on `gluster1`, `gluster2` and `gluster3`
![](./Images/thenewstack.png)

## Benchmarking
We use [fio](https://github.com/axboe/fio) to do the benchmarking.

### Prerequisites
```
sudo apt install gcc make libaio-dev -y
```

Permissions to run the tests
```
sudo chmod -R 777 /mnt/glusterfs
sudo chown -R $(whoami):$(whoami) /mnt/glusterfs
```

### Setting up FIO
On the Client `gluster4` run the following commands:
```
git clone https://github.com/axboe/fio.git
cd fio
./configure
make
sudo make install
```

### Testing
The tests we have used are given below.

1. Sequential Write Test
2. Sequential Read Test
3. Random Read Test
4. Random Write Test

#### Running all the above tests
```
fio test.fio
```
