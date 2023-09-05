# Getting started with containerd
This tutorial explains how to install `containerd` and all it's dependencies from the official binaries.

> [!WARNING]  
> This should NOT be used for production Kubernetes cluster. Use at your own risk.

> [!NOTES]
>All binaries are built statically and should work on any Linux distribution with `glibc`.

Remove old `containerd`
```sh
sudo nala remove containerd.io
sudo nala purge containerd.io
```

## Step 1: Installing `containerd`
Get the latest version of `containerd`:
```sh
VER=$(curl -s https://api.github.com/repos/containerd/containerd/releases/latest | grep tag_name | cut -d '"' -f 4|sed 's/v//g')
echo ${VER}

# Download and extract the archive file from Github release page
curl -LO https://github.com/containerd/containerd/releases/download/v${VER}/containerd-${VER}-linux-amd64.tar.gz
 
# Extract binary package in `/usr/local/bin` with the command:
sudo tar Cxzvf /usr/local containerd-${VER}-linux-amd64.tar.gz
```

Prepare `containerd` configuration file for K8s:
```sh
sudo mkdir /etc/containerd/
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

If you intend to start `containerd` via `systemd`, you need to download the `containerd.service` file:
```sh
curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mv containerd.service /lib/systemd/system/.
sudo chown root:root /lib/systemd/system/containerd.service
sudo systemctl daemon-reload
sudo systemctl unmask containerd.service
sudo systemctl enable --now containerd
```

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

## Step 2: Installing `runc`
Download the runc.<ARCH> binary and install it in `/usr/local/sbin/runc`.

```sh
VER=$(curl -s https://api.github.com/repos/opencontainers/runc/releases/latest | grep tag_name | cut -d '"' -f 4|sed 's/v//g')
echo ${VER}

# Download and extract the archive file from Github release page
curl -LO https://github.com/opencontainers/runc/releases/download/v${VER}/runc.amd64
sudo install -m 755 runc.amd64 /usr/local/sbin/runc
```

## Step 3: Installing CNI plugins
```sh
VER=$(curl -s https://api.github.com/repos/containernetworking/plugins/releases/latest | grep tag_name | cut -d '"' -f 4|sed 's/v//g')
echo ${VER}

# Download and extract the archive file from Github release page
curl -LO https://github.com/containernetworking/plugins/releases/download/v${VER}/cni-plugins-linux-amd64-v${VER}.tgz
 
# Extract binary package in `/opt/cni/bin/` with the command:
sudo sudo tar Cxzvf /opt/cni/bin/ cni-plugins-linux-amd64-v${VER}.tgz
```

# References
[Getting started with containerd](https://github.com/containerd/containerd/blob/main/docs/getting-started.md)  
[](https://github.com/containernetworking/plugins)  
[Docker](https://download.docker.com/linux/ubuntu/dists/)  
