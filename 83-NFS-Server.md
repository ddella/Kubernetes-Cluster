# Prepare Ubuntu Server 22.04.3 for kubernetes
This tutorial shows how to prepare a Ubuntu Server 22.04.3 to act as:

- Nginx load balancer for Kubernetes API
- Linux NFS server
- Linux Jump Station to configure/monitor a Kubernetes cluster

>This is a real server that is not part of Kubernetes cluster. It has to be up before we create the cluster, expecially the API load balancer part.

## Configurations
|Role|FQDN|IP|OS|Kernel|RAM|vCPU|
|----|----|----|----|----|----|----|
|Load Balancer|k8svrrp.isociel.com|192.168.13.70|N/A|N/A||N/A||N/A||
|Nginx Primary|k8svrrp1.isociel.com|192.168.13.71|Ubuntu 22.04.2|6.4.12|2G|2|
|Nginx Secondary|k8svrrp2.isociel.com|192.168.13.72|Ubuntu 22.04.2|6.4.12|2G|2|

# NFS Server
## Definition of NFS
Network File System (NFS), is a distributed file system that allows various clients to access a shared directory on a server.

## Update Repos
Update the Ubuntu repo with the following commands:
```sh
sudo apt update
```

## Install NFS Server
Install NFS server:
```sh
sudo apt install nfs-kernel-server
```

## Configure NFS Server
Create the mount point directory:
```sh
sudo mkdir /nfs-data
```

Change the permissions and ownership to match the following (Be sure that you know what you are doing):
```sh
sudo chown nobody:nogroup /nfs-data
sudo chmod -R 777 /nfs-data/
```

Create the file exports for NFS server:
```sh
cat << EOF | sudo tee -a /etc/exports
/nfs-data 192.168.13.0/24(rw,no_subtree_check,no_root_squash)
EOF
```

Export it to the client(s):
```sh
sudo exportfs -arv
```

>**Note:** Remember to re-export your shares on the server with `sudo exportfs -arv` if you make changes! The NFS server won’t pick them up automatically.  

## Start NFS
Start the service and make it persistant:
```sh
sudo systemctl start nfs-kernel-server.service
sudo systemctl enable nfs-kernel-server.service
```

## Verification
Check the status of NFS. Look for any kind of error/warning:
```sh
sudo systemctl status nfs-kernel-server.service
```

Verify the NFS version (you can see this information in column two):
```sh
rpcinfo -p | grep nfs
```

 Display the currently running exports with:
 ```sh
 sudo exportfs -v
 ```

>**Note**:For every client, every K8s worker node, you will need to install the client portion of NFS. Failure to do so will make Pods incapable of mounting an NFS drive

<p align="right">(<a href="#readme-top">back to top</a>)</p>
