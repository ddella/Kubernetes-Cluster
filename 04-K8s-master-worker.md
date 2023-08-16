<a name="readme-top"></a>

# Prepare server for Kubernetes
This tutorial shows how to prepare a Ubuntu server to become part of a Kubernetes Cluster as either a master or worker node.

# Before you begin
To follow this guide, you need:

- a server that we prepared from this tutorial [here](01_Ubuntu-22-04.md).
- 2 GiB or more of RAM per machine.
- At least 2 vCPUs on the machine that you use as a control-plane node.
- Full network connectivity among all machines in the cluster.
- Internet Connectivity

# Objectives
- Install `kubectl`, `kubelet` and `kubeadm`
- Install [containerd](https://containerd.io/) as the CRE for Kubernetes
- Install [crictl](https://github.com/kubernetes-sigs/cri-tools)
- Install [nerdctl](https://github.com/containerd/nerdctl)

# Install `kubectl`, `kubelet` and `kubeadm`
> **Note**
>Kubernetes has two different package repositories starting from August 2023. The Google-hosted repository is deprecated and it's being replaced with the Kubernetes (community-owned) package repositories. The Kubernetes project strongly recommends using the Kubernetes community-owned package repositories, because the project plans to stop publishing packages to the Google-hosted repository in the future.

>There are some important considerations for the Kubernetes package repositories:
>- The Kubernetes package repositories contain packages beginning with those Kubernetes versions that were still under support when the community took over the package builds. This means that anything before v1.24.0 will only be available in the Google-hosted repository.
>- There's a dedicated package repository for each Kubernetes minor version. When upgrading to to a different minor release, you must bear in mind that the package repository details also change.

Install packages dependency:
```sh
sudo apt install apt-transport-https ca-certificates
```

Download the public signing key for the Kubernetes package repositories. The same signing key is used for all repositories so you can disregard the version in the URL:
```sh
curl -fsSL https://pkgs.k8s.io/core:/stable:/v1.28/deb/Release.key | sudo gpg --dearmor -o /etc/apt/keyrings/kubernetes-apt-keyring.gpg
```

Add the Kubernetes repository:
```sh
echo 'deb [signed-by=/etc/apt/keyrings/kubernetes-apt-keyring.gpg] https://pkgs.k8s.io/core:/stable:/v1.28/deb/ /' | sudo tee /etc/apt/sources.list.d/kubernetes.list
```

Update the apt package index, install kubelet, kubeadm and kubectl, and pin their version:
```sh
sudo apt update
sudo apt install -y kubelet kubeadm kubectl
sudo apt-mark hold kubelet kubeadm kubectl
```

Verify K8s version:
```sh
kubectl version --output=yaml
kubeadm version --output=yaml
```

>You'll get the following error message from **kubectl**: `The connection to the server localhost:8080 was refused - did you specify the right host or port?`. We haven't installed anything yet. It's a normal problem 😂!

Enable `kubectl` and `kubeadm` autocompletion for Bash:
```sh
sudo kubectl completion bash | sudo tee /etc/bash_completion.d/kubectl > /dev/null
sudo kubeadm completion bash | sudo tee /etc/bash_completion.d/kubeadm > /dev/null
```

After reloading your shell, `kubectl` and `kubeadm` autocompletion should be working.
```sh
source ~/.bashrc
```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

# `containerd`
To run containers, Kubernetes needs a Container Runtime Engine. That CRE must be compliant with K8s Container Runtime Interface (CRI). CRE runs containers on a host operating system and is responsible for loading container images from a repository, monitoring local system resources, isolating system resources for use of a container, and managing container lifecycle. 

The supported CRE with K8s are:

- Docker
- CRI-O
- **Containerd**

For this tutorial, we will install [containerd](https://containerd.io/) as our CRE. Containerd is officially a graduated project within the Cloud Native Computing Foundation as of 2019 🍾🎉🥳🎁

## Install `containerd`
Install packages dependency (already done in the preceeding step):
```sh
# sudo apt install apt-transport-https ca-certificates
```

Add Docker's Official GPG Key (we're not installing Docker just `containerd`):
```sh
curl -fsSL https://download.docker.com/linux/ubuntu/gpg | sudo gpg --dearmor -o /usr/share/keyrings/docker-archive-keyring.gpg
```

Add Docker Repo to Ubuntu:
```sh
echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/ubuntu $(lsb_release -cs) stable" | sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
```

Refresh the package list and make sure there's no error regarding the `gpg key`:
```sh
sudo apt update
```

To install the latest up-to-date `containerd` release on Ubuntu, run the below command:
```sh
sudo apt install containerd.io
```

Verify that containerd is indeed installed:
```sh
dpkg -l containerd.io
```

Output:
```
Desired=Unknown/Install/Remove/Purge/Hold
| Status=Not/Inst/Conf-files/Unpacked/halF-conf/Half-inst/trig-aWait/Trig-pend
|/ Err?=(none)/Reinst-required (Status,Err: uppercase=bad)
||/ Name           Version      Architecture Description
+++-==============-============-============-======================================
ii  containerd.io  1.6.21-1     amd64        An open and reliable container runtime
```

## Configure `containerd`
Prepare the configuration of `containerd` . If you start `kubeadm ...` without adjusting the configuration, you will get the following error:

```
[preflight] Running pre-flight checks
error execution phase preflight: [preflight] Some fatal errors occurred:
        [ERROR CRI]: container runtime is not running: output: time="2023-05-18T18:56:56Z" level=fatal msg="validate service connection: CRI v1 runtime API is not implemented for endpoint \"unix:///var/run/containerd/containerd.sock\": rpc error: code = Unimplemented desc = unknown service runtime.v1.RuntimeService"
, error: exit status 1
```

Prepare `containerd` configuration file for K8s:
```sh
sudo rm /etc/containerd/config.toml
sudo containerd config default | sudo tee /etc/containerd/config.toml > /dev/null
```

Edit the configuration file `/etc/containerd/config.toml`. In the section `[plugins."io.containerd.grpc.v1.cri".containerd.runtimes.runc.options]`, change the key `SystemdCgroup` to true. You can use the following command or your prefered text editor:
```sh
sudo sed -i 's/SystemdCgroup = false/SystemdCgroup = true/' /etc/containerd/config.toml
```

If you don't want to specify the endpoint every time you use the command `crictl`, you can create the file `/etc/crictl.yaml` by specifying the endpoint. If you don't create the file, you'll have to enter the endpoint each time like this: `crictl --runtime-endpoint unix:///run/containerd/containerd.sock ...`
```sh
cat <<EOF | sudo tee /etc/crictl.yaml > /dev/null
runtime-endpoint: unix:///var/run/containerd/containerd.sock
image-endpoint: unix:///var/run/containerd/containerd.sock
EOF
```
<p align="right">(<a href="#readme-top">back to top</a>)</p>

### Fix issue with 
To get rid of the warning message below when doing `kubeadm init`:
```
W0714 13:38:17.059546   33985 checks.go:835] detected that the sandbox image "registry.k8s.io/pause:3.6" of the container runtime is inconsistent with that used by kubeadm. It is recommended that using "registry.k8s.io/pause:3.9" as the CRI sandbox image.
```

Change the container version:
```sh
sudo sed -i 's/sandbox_image \= \"registry.k8s.io\/pause:3.6\"/sandbox_image \= \"registry.k8s.io\/pause:3.9\"/' /etc/containerd/config.toml
```

Restart the service and check it's status:
```sh
sudo systemctl restart containerd
sudo systemctl status containerd
```

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
<p align="right">(<a href="#readme-top">back to top</a>)</p>

# Install `nerdctl`
ContaiNERD CTL is a command-line tool for managing containers for the `containerd` Container Runtime. It's compatible with Docker CLI for Docker and has the same UI/UX as the "docker" command. 

Get the latest version and download `nerdctl` binary file. Extract it to `/usr/local/bin`:

Get the latest version of `nerdctl`:
```sh
VER=$(curl -s https://api.github.com/repos/containerd/nerdctl/releases/latest | grep tag_name | cut -d '"' -f 4|sed 's/v//g')
echo ${VER}
```

Download and extract the archive file from Github nerdctl releases page
```sh
curl -LO https://github.com/containerd/nerdctl/releases/download/v${VER}/nerdctl-${VER}-linux-amd64.tar.gz
```
 
Move `nerdctl` binary package to `/usr/local/bin` directory with the command:
```sh
sudo tar Cxzvf /usr/local/bin nerdctl-${VER}-linux-amd64.tar.gz
sudo chown root:adm /usr/local/bin/nerdctl
```

Don't do the next step - DIDN'T WORK FOR ME !!!
```sh
echo "kernel.unprivileged_userns_clone = 1" | sudo tee /etc/sysctl.d/90-nerdctl-rootless.conf > /dev/null
sudo sysctl --system
sudo sysctl -p /etc/sysctl.d/90-nerdctl-rootless.conf
containerd-rootless-setuptool.sh install
```

Cleanup
```sh
rm nerdctl-${VER}-linux-amd64.tar.gz
unset VER
```

## Example of `nerdctl`
`containerd` supports namespaces at the container runtime level. These namespaces are entirely different from the K8s namespaces. `containerd` namespaces are used to provide isolation to different applications that might be using `containerd` like docker, kubelet, etc. Below are two well-known namespaces.

- K8s.io: contains all the containers started from the CRI plugin by `kubelet`, irrespective of the namespace in Kubernetes
- moby: comprises all containers started by docker

```sh
sudo nerdctl --namespace k8s.io image ls
```

<p align="right">(<a href="#readme-top">back to top</a>)</p>

# Stop 
Congratulations! You have a fully functional Linux Ubuntu 22.04 ready to be part in a Kubernetes Cluster as either a master or worker node 🎉  

<a name="k8s-master"></a>
<p align="right">(<a href="#readme-top">back to top</a>)</p>

# Next Steps 
The next steps would be to configure one and more K8s master node.

# License
Distributed under the MIT License. See [LICENSE](LICENSE) for more information.
<p align="right">(<a href="#readme-top">back to top</a>)</p>

# Contact
Daniel Della-Noce - [Linkedin](https://www.linkedin.com/in/daniel-della-noce-2176b622/) - daniel@isociel.com  
Project Link: [https://github.com/ddella/Debian11-Docker-K8s](https://github.com/ddella/Debian11-Docker-K8s)
<p align="right">(<a href="#readme-top">back to top</a>)</p>

# Reference
[Good reference for K8s and Ubuntu](https://computingforgeeks.com/install-kubernetes-cluster-ubuntu-jammy/)  
[Install latest Ubuntu Linux Kernel](https://linux.how2shout.com/linux-kernel-6-2-features-in-ubuntu-22-04-20-04/#5_Installing_Linux_62_Kernel_on_Ubuntu)  
[Containerd configuration file modification for K8s](https://devopsquare.com/how-to-create-kubernetes-cluster-with-containerd-90399ec3b810)  
[apt-key deprecated](https://itsfoss.com/apt-key-deprecated/)  
[Why Use nerdctl for containerd](https://blog.devgenius.io/k8s-why-use-nerdctl-for-containerd-f4ea49bcf900)  
