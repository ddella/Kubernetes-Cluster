<a name="readme-top"></a>

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

<p align="right">(<a href="#readme-top">back to top</a>)</p>


# References
[Official GitHub for nerdctl](https://github.com/containerd/nerdctl)  
[K8s — Why Use nerdctl for containerd](https://blog.devgenius.io/k8s-why-use-nerdctl-for-containerd-f4ea49bcf900)  
[How to use nerdctl if you are familiar with Docker CLI](https://technotes.adelerhof.eu/containers/containerd/nerdctl/)  
