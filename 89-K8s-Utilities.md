# Popey
Popeye is a utility that scans live Kubernetes cluster and reports potential issues with deployed resources and configurations. It sanitizes your cluster based on what's deployed and not what's sitting on disk. By scanning your cluster, it detects misconfigurations and helps you to ensure that best practices are in place, thus preventing future headaches. It aims at reducing the cognitive overload one faces when operating a Kubernetes cluster in the wild. Furthermore, if your cluster employs a metric-server, it reports potential resources over/under allocations and attempts to warn you should your cluster run out of capacity.

> [!IMPORTANT]  
> Popeye is a readonly tool, it does not alter any of your Kubernetes resources in any way!

## Download
Download and install the latest version of `popey` with the commands:
```sh
VER=$(curl -s https://api.github.com/repos/derailed/popeye/releases/latest | grep tag_name)
echo ${VER}
curl -LO https://github.com/derailed/popeye/releases/download/${VER}/popeye_Linux_x86_64.tar.gz
sudo tar Czxvf /usr/local/bin popeye_Linux_x86_64.tar.gz popeye
sudo chown root:adm /usr/local/bin/popeye
rm -f popeye_Linux_x86_64.tar.gz
```

## Example
Example to save report in working directory in HTML format under the name "report.html" :
```sh
POPEYE_REPORT_DIR=$(pwd) popeye --save --out html --output-file report.html
```

# References
[Popeye - A Kubernetes Cluster Sanitizer](https://popeyecli.io/)  
[Popeye - GitHub Repo](https://github.com/derailed/popeye/releases)  

---

# K9s Installation
K9s is a terminal based UI to interact with your Kubernetes clusters. The aim of this project is to make it easier to navigate, observe and manage your deployed applications in the wild. K9s continually watches Kubernetes for changes and offers subsequent commands to interact with your observed resources.

# Install
Installation from binaries for Linux.

- Get the release
- Download the binary
- Move it to /usr/local/bin/

```sh
export VER=$(curl -L https://github.com/derailed/k9s/releases/latest | grep "<title>Release" | awk -F ' ' '{print $2}') > /dev/null
echo ${VER}
curl -LO https://github.com/derailed/k9s/releases/download/${VER}/k9s_Linux_amd64.tar.gz
tar -xzvf k9s_Linux_amd64.tar.gz
sudo mv k9s /usr/local/bin/
unset VER
```

# References
[K9s Install](https://k9scli.io/topics/install/)  
[K9s Commands](https://k9scli.io/topics/commands/)  

---

# Stern
Stern allows you to `tail` multiple pods on Kubernetes and multiple containers within the pod. Each result is color coded for quicker debugging.

The query is a regular expression or a Kubernetes resource in the form `<resource>/<name>` so the pod name can easily be filtered and you don't need to specify the exact id (for instance omitting the deployment id). If a pod is deleted it gets removed from tail and if a new pod is added it automatically gets tailed.

When a pod contains multiple containers Stern can tail all of them too without having to do this manually for each one. Simply specify the `container` flag to limit what containers to show. By default all containers are listened to.

## Install
Installation from binaries for Linux.
```sh
export VER=$(curl -L https://github.com/stern/stern/releases/latest | grep "<title>Release" | awk -F ' ' '{print $2}' | sed 's/v//g') > /dev/null
echo ${VER}
curl -LO https://github.com/stern/stern/releases/download/v${VER}/stern_${VER}_linux_amd64.tar.gz
sudo tar Czxvf /usr/local/bin stern_${VER}_linux_amd64.tar.gz stern
sudo chown root:adm /usr/local/bin/stern
rm -f stern_${VER}_linux_amd64.tar.gz
unset VER
```

## Examples
To tail the logs of all the `coredns` Pods:
```sh
stern -n kube-system -l k8s-app=kube-dns
```

# References
[Stern - GitHub Repo](https://github.com/stern/stern)  

---

# Install `etcdctl`
`etcd` is distributed, reliable key-value store for the most critical data of a distributed system. i=It's a strongly consistent, distributed key-value store that provides a reliable way to store data that needs to be accessed by a distributed system or cluster of machines. It gracefully handles leader elections during network partitions and can tolerate machine failure, even in the leader node.

`etcdctl` is a command line tool for interacting with the `etcd` database(s) in Kubernetes.

## Install Latest
```sh
export VER=$(curl -s https://api.github.com/repos/etcd-io/etcd/releases/latest|grep tag_name | cut -d '"' -f 4)
curl -LO https://github.com/etcd-io/etcd/releases/download/${VER}/etcd-${VER}-linux-amd64.tar.gz
tar xvf etcd-${VER}-linux-amd64.tar.gz
cd etcd-${VER}-linux-amd64
sudo cp etcdctl etcdutl /usr/local/bin/
sudo chown root:adm /usr/local/bin/etcdctl /usr/local/bin/etcdutl
```

## Verify installation
```sh 
etcdctl version
etcdutl version
```

## Cleanup
```sh
cd ..
rm -rf etcd-${VER}-linux-amd64
rm etcd-${VER}-linux-amd64.tar.gz
unset VER
```

# References
[Main site](https://etcd.io/docs/v3.4/dev-guide/interacting_v3/)  
[GitHub](https://github.com/etcd-io/etcd/tree/main/etcdctl)  
[Libraries and tools](https://etcd.io/docs/v3.5/integrations/)

---

# What is `nerdctl`
`nerdctl` is a Docker compatible CLI for `containerd` CRE. Unlike `ctr` and `crictl`, `nerdctl` goals is to be user-friendly and Docker-compatible. K8s deprecated Docker shim in v1.24 and `containerd` became the new default container runtime. Therefore, Docker CLI tool no longer works in K8s. A new tool is needed for container level management.

# Install `nerdctl`
ContaiNERD CTL is a command-line tool for managing containers for the `containerd` Container Runtime. It's compatible with Docker CLI for Docker and has the same UI/UX as the "docker" command. 

Get the latest version and download `nerdctl` binary file. Extract it to `/usr/local/bin`:

Get the latest version of `nerdctl`:
```sh
# Get the latest version
VER=$(curl -s https://api.github.com/repos/containerd/nerdctl/releases/latest | grep tag_name | cut -d '"' -f 4|sed 's/v//g')
echo ${VER}
# Download and extract the archive file
curl -LO https://github.com/containerd/nerdctl/releases/download/v${VER}/nerdctl-${VER}-linux-amd64.tar.gz 
# Move nerdctl binary package
sudo tar Cxzvf /usr/local/bin nerdctl-${VER}-linux-amd64.tar.gz
sudo chown root:adm /usr/local/bin/nerdctl
# Cleanup
rm nerdctl-${VER}-linux-amd64.tar.gz
unset VER
```

Don't do the next step - DIDN'T WORK FOR ME !!!
```sh
echo "kernel.unprivileged_userns_clone = 1" | sudo tee /etc/sysctl.d/90-nerdctl-rootless.conf > /dev/null
sudo sysctl --system
sudo sysctl -p /etc/sysctl.d/90-nerdctl-rootless.conf
containerd-rootless-setuptool.sh install
```

## Example of `nerdctl`
`containerd` supports namespaces at the container runtime level. These namespaces are entirely different from the K8s namespaces. `containerd` namespaces are used to provide isolation to different applications that might be using `containerd` like docker, kubelet, etc. Below are two well-known namespaces.

- K8s.io: contains all the containers started from the CRI plugin by `kubelet`, irrespective of the namespace in Kubernetes
- moby: comprises all containers started by docker

```sh
sudo nerdctl --namespace k8s.io image ls
```

# References
[Official GitHub for nerdctl](https://github.com/containerd/nerdctl)  
[K8s - Why Use nerdctl for containerd](https://blog.devgenius.io/k8s-why-use-nerdctl-for-containerd-f4ea49bcf900)  
[How to use nerdctl if you are familiar with Docker CLI](https://technotes.adelerhof.eu/containers/containerd/nerdctl/)  

---

# Install `crictl`
`crictl` provides a CLI for CRI-compatible container runtimes. This allows the CRI runtime developers to debug their runtime without needing to set up Kubernetes components. `crictl` is currently in Beta and still under quick iterations. It is hosted at the cri-tools repository.

```sh
export VER=$(curl -L https://github.com/kubernetes-sigs/cri-tools/releases/latest | grep "<title>Release" | awk -F ' ' '{print $2}') > /dev/null
echo ${VER}
```

Make sure the version make sense. This command above is not the usual way to get the latest version number
```sh
curl -LO https://github.com/kubernetes-sigs/cri-tools/releases/download/${VER}/crictl-${VER}-linux-amd64.tar.gz
sudo tar zxvf crictl-${VER}-linux-amd64.tar.gz -C /usr/local/bin
sudo chown root:adm /usr/local/bin/crictl
rm -f crictl-${VER}-linux-amd64.tar.gz
unset VER
```

Enable `crictl` autocompletion for Bash:
```sh
sudo crictl completion | sudo tee /etc/bash_completion.d/crictl > /dev/null
source ~/.bashrc
```

## Use `crictl` without sudo
> [!IMPORTANT]  
> This should be done locally on a K8s node.

By default each time you run the command `crictl` you'll need to prefix it with `sudo`. You can change the group permission of the API socket by:
- adding a new group like `crictl`
- add your user(s) to the group `crictl`
- modify the file `/etc/containerd/config.toml` to change the group owner of `/var/run/containerd/containerd.sock`

Add a new group to run the command `crictl` commands without using `sudo`:
```sh
sudo addgroup crictl
```

Enabling your non-root user to be part of the group `crictl`(Log out from the current terminal and log back in):
```sh
sudo usermod -aG crictl ${USER}
```

Modify the file `/etc/containerd/config.toml` to change the GID of `/var/run/containerd/containerd.sock` to the GID of the group `crictl`:
```sh
sudo sed -i "s/gid = 0/gid = $(getent group crictl | cut -d: -f3)/" /etc/containerd/config.toml
```

Restart the `containerd.service` service and check that it has been restarted without any **ERROR MESSAGES**:
```sh
sudo systemctl restart containerd
sudo systemctl status containerd
```

The file `/run/containerd/containerd.sock` should be owned by the group `crictl` 
```
srw-rw---- 1 root crictl 0 May 23 08:31 /run/containerd/containerd.sock
```

**Logoff** and log back in for the changes to take effect and test the command without `sudo`:
```sh
crictl version
```

The output should look like this:
```
Version:  0.1.0
RuntimeName:  containerd
RuntimeVersion:  1.6.21
RuntimeApiVersion:  v1
```
---

