<a name="readme-top"></a>

# Prepare Ubuntu Server 22.04.2 for kubernetes
This tutorial shows how to prepare a Ubuntu Server 22.04.2 to act as:

- Nginx load balancer for Kubernetes API
- Linux NFS server
- Linux Jump Station to configure/monitor a Kubernetes cluster

>This is a real server that is not part of Kubernetes cluster. It has to be up before we create the cluster, expecially the API load balancer part.

## Configurations
|Role|FQDN|IP|OS|Kernel|RAM|vCPU|
|----|----|----|----|----|----|----|
|Load Balancer|k8sapi.isociel.com|192.168.13.60|Ubuntu 22.04.2|6.4.3|4G|4|

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

------------------------------
# Nginx as a load balancer
This section is about configuring an Nginx reverse proxy/load balancer to front the Kubernetes API server. We are building a K8s cluster in high availability with at least three (3) master node. When a request arrives for Kubernetes API, Nginx becomes a proxy and further forward that request to any healthy K8s Master node, then it forwards the response back to the client.

This assumes that:
- K8s API server runs on port 6443 with HTTPS
- All K8s Master node runs the API via the URL: http://<master node>:6443

Nginx will run on a bare metal Ubuntu server outside the K8s cluster.

##  What is a Reverse Proxy
Proxying is typically used to distribute the load among several servers, seamlessly show content from different websites, or pass requests for processing to application servers over protocols other than HTTP.

When NGINX proxies a request, it sends the request to a specified proxied server, fetches the response, and sends it back to the client.

In this tutorial, Nginx Reverse proxy receive inbound `HTTPS` requests and forward those requests to the K8s master nodes. It receives the outbound `HTTP` response from the API servers and forwards those requests to the original requester.

## Installing from the Official NGINX Repository
NGINX Open Source is available in two versions:

- **Mainline** – Includes the latest features and bug fixes and is always up to date. It is reliable, but it may include some experimental modules, and it may also have some number of new bugs.
- **Stable** – Doesn’t include all of the latest features, but has critical bug fixes that are always backported to the mainline version. We recommend the stable version for production servers.

Of course I chooses the `Mainline` version to get all the latest features 😀

Install the prerequisites:
```sh
sudo apt install curl gnupg2 ca-certificates lsb-release debian-archive-keyring
```

Import an official nginx signing key so `apt` could verify the packages authenticity. Fetch the key with the command:
```sh
curl https://nginx.org/keys/nginx_signing.key | gpg --dearmor \
| sudo tee /usr/share/keyrings/nginx-archive-keyring.gpg >/dev/null
```
Verify that the downloaded file contains the proper key:
```sh
gpg --dry-run --quiet --no-keyring --import --import-options import-show /usr/share/keyrings/nginx-archive-keyring.gpg
```

If the output is different **stop** and try to figure out what happens:
```
pub   rsa2048 2011-08-19 [SC] [expires: 2024-06-14]
      573BFD6B3D8FBC641079A6ABABF5BD827BD9BF62
uid                      nginx signing key <signing-key@nginx.com>
```

Run the following command to use `mainline` Nginx packages:
```sh
echo "deb [signed-by=/usr/share/keyrings/nginx-archive-keyring.gpg] \
https://nginx.org/packages/mainline/ubuntu/ `lsb_release -cs` nginx" | sudo tee /etc/apt/sources.list.d/nginx.list
```

Set up repository pinning to prefer our packages over distribution-provided ones:
```sh
echo -e "Package: *\nPin: origin nginx.org\nPin: release o=nginx\nPin-Priority: 900\n" \
| sudo tee /etc/apt/preferences.d/99nginx
```

Update the repo and install NGINX:
```sh
sudo apt update
sudo apt install nginx
```

## Checking Nginx
Start and check that Nginx is running:
```sh
sudo systemctl start nginx
sudo systemctl status nginx
```

Try with `cURL`, you should receive the Nginx welcome page:
```sh
curl http://127.0.0.1
```

## Configure Nginx for layer 4 Load Balancing
This will be the initial configuration of Nginx. I've never been able to bootstrap a Kubernetes Cluster with a layer 7 Load Balancer due the `mTLS` configuration.

Create another directory for our layer 4 Load Balancer. The reason is that the directive in `nginx.conf` file for our layer 4 and layer 7 load balancer are in different section:
```sh
sudo mkdir /etc/nginx/tcpconf.d/
```

Create the configuration file. This one will be active:
```sh
sudo cat <<'EOF' | sudo tee /etc/nginx/tcpconf.d/k8sapi.conf >/dev/null
stream {
    log_format k8sapilogs '[$time_local] $remote_addr:$remote_port $server_addr:$server_port '
        '$protocol $status $bytes_sent $bytes_received '
        '$session_time';
    upstream k8s-api {
        server k8smaster1.isociel.com:6443;
        server k8smaster2.isociel.com:6443;
        server k8smaster3.isociel.com:6443;
    }
    server {
        listen 6443;

        proxy_pass k8s-api;
        access_log /var/log/nginx/k8sapi.access.log k8sapilogs;
        error_log /var/log/nginx/k8sapi.error.log warn;
    }
}
EOF
```
>**Note**: Don't forget the quote around `'EOF'`. We need the variables inside the file not the values of those variables

Add a directive in the `nginx.conf` to parse all the `.conf` file in the new directory we created:
```sh
cat <<EOF | sudo tee -a /etc/nginx/nginx.conf >/dev/null
include /etc/nginx/tcpconf.d/*.conf;
EOF
```

**Important**: Verify Nginx configuration files with the command:
```sh
sudo nginx -t
```
>**Note**: If you don't use `sudo`, you'll get some weird alerts

Restart and check status Nginx server:
```sh
sudo systemctl restart nginx
sudo systemctl status nginx
```

## Verify the load balancer
On the server `k8sapi.isociel.com` check Nginx logs with the command:
```sh
sudo tail -f /var/log/nginx/k8sapi.error.log 
```

When a client tries to connect, you should see this output. Since we don't have a K8s cluster yet, Nginx will try all the servers in the group and it will receive a `Connection refused`.
```
2023/07/12 15:48:12 [error] 9013#9013: *9 connect() failed (111: Connection refused) while connecting to upstream, client: 192.168.13.104, server: k8sapi.isociel.com, request: "GET / HTTP/1.1", upstream: "https://192.168.13.63:6443/", host: "192.168.13.60:6443"
2023/07/12 15:48:12 [error] 9013#9013: *9 connect() failed (111: Connection refused) while connecting to upstream, client: 192.168.13.104, server: k8sapi.isociel.com, request: "GET / HTTP/1.1", upstream: "https://192.168.13.62:6443/", host: "192.168.13.60:6443"
2023/07/12 15:48:12 [error] 9013#9013: *9 connect() failed (111: Connection refused) while connecting to upstream, client: 192.168.13.104, server: k8sapi.isociel.com, request: "GET / HTTP/1.1", upstream: "https://192.168.13.61:6443/", host: "192.168.13.60:6443"
```

From another machine, try to connect to the K8s API loab balancer, with the command (no need for the `--insecure` flag):
```sh
curl --max-time 10 https://k8sapi.isociel.com:6443
```

Output on the client:
```
<html>
<head><title>502 Bad Gateway</title></head>
<body>
<center><h1>502 Bad Gateway</h1></center>
<hr><center>nginx/1.25.1</center>
</body>
</html>
```

>Both outputs are normal, since we don't have a K8s master node yet 😀

# Conclusion
You have a Ubuntu server that:
- Acts as an NFS server for K8s volumes claim
- Acts as a load balancer for all API requests to K8s (ex.: `kubectl` command)
- Acts as a jump station to manage/monitor your K8s cluster

# References
[Nginx Load Balancer](https://nginx.org/en/docs/http/load_balancing.html)  
[Installing NGINX Open Source](https://docs.nginx.com/nginx/admin-guide/installing-nginx/installing-nginx-open-source/)  
