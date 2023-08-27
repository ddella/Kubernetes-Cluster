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

If you intend to start `containerd` via `systemd`, you need to download the `containerd.service` file:
```sh
curl -LO https://raw.githubusercontent.com/containerd/containerd/main/containerd.service
sudo mv containerd.service /usr/lib/systemd/system/.
sudo systemctl daemon-reload
sudo rm /etc/systemd/system/containerd.service
sudo ln -s /usr/lib/systemd/system/containerd.service /etc/systemd/system/containerd.service
sudo systemctl enable --now containerd
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
