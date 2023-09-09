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

[Changing The Kubernetes Package Repository](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/change-package-repository/)  

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

Use [this page](./09-ContainerD.md)

## Install `ipvs`
Kube-proxy can run in one of three modes, each implemented with different data plane technologies:
- userspace
- iptables
- IPVS

I strongly suggest to use `ipvs`. You will need to install it. Follow the instruction [here](./88-IPVS.md) to install `ipvs` on Ubuntu 22.04.

# Stop 
Congratulations! You have a fully functional Linux Ubuntu 22.04 ready to be part in a Kubernetes Cluster as either a master or worker node 🎉  

The next steps are:
- BootStrap the Cluster
- Join more Master and Worker Nodes

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
