# Install buildkit (Alpha)
BuildKit is composed of the `buildkitd` daemon and the `buildctl` client. While the `buildctl` client is available for Linux, macOS, and Windows, the `buildkitd` daemon is only available for Linux currently.

The buildkitd daemon requires the following components to be installed:

- runc or crun
- containerd (if you want to use containerd worker)

This tutorial shows how to install `buildkit`.

**This as not been tested. USE AT YOUR OWN RISK.**

### Get the latest binaries
```sh
VER=$(curl -s https://api.github.com/repos/moby/buildkit/releases/latest | grep tag_name | cut -d '"' -f 4|sed 's/v//g')
echo ${VER}
curl -LO https://github.com/moby/buildkit/releases/download/v${VER}/buildkit-v${VER}.linux-amd64.tar.gz
sudo mv bin/buildkitd bin/buildctl bin/buildkit-runc /usr/local/bin/.
rm -rf bin
rm -f buildkit-v${VER}.linux-amd64.tar.gz
unset VER
```

### Build the service files
To start the `buildkitd` daemon using `systemd` socket activation, you can install the buildkit `systemd` unit files below:

Service file:
```sh
cat <<EOF | sudo tee /usr/lib/systemd/system/buildkit.service > /dev/null
[Unit]
Description=BuildKit
Requires=buildkit.socket
After=buildkit.socket
Documentation=https://github.com/moby/buildkit

[Service]
Type=notify
ExecStart=/usr/local/bin/buildkitd --oci-worker=false --containerd-worker=true

[Install]
WantedBy=multi-user.target
EOF
```

Socket file:
```sh
cat <<EOF | sudo tee /usr/lib/systemd/system/buildkit.socket > /dev/null
[Unit]
Description=BuildKit
Documentation=https://github.com/moby/buildkit
PartOf=buildkit.service

[Socket]
ListenStream=%t/buildkit/buildkitd.sock
SocketMode=0660

[Install]
WantedBy=sockets.target
EOF
```

### Start the service
```sh
# Reload systemd & check it's status
sudo systemctl daemon-reload
sudo systemctl status

# Start buildkit, check it's status and enable it to survive restart
sudo systemctl start buildkit
sudo systemctl status buildkit
sudo systemctl enable buildkit
```

### Test buildkit
Let's build a Docker image with buildkit. This assume you don't have Docker on your workstation.

Make a simple `Dockerfile`:
```sh
cat <<EOF > Dockerfile
FROM alpine:3.18.3

RUN apk add --no-cache curl
EOF
```

Build the image:
```sh
sudo nerdctl build -t test .
```

Verify that the image has been created:
```sh
sudo nerdctl image ls
```

```
REPOSITORY    TAG       IMAGE ID        CREATED          PLATFORM       SIZE       BLOB SIZE
test          latest    be113444f955    2 minutes ago    linux/amd64    9.9 MiB    5.1 MiB
```

### Cleanup
Remove the image:
```sh
sudo nerdctl image rm test:latest
```

Remove the  `Dockerfile`
```sh
rm -f  Dockerfile
```

# References
[Buildkit - GitHub](https://github.com/moby/buildkit/tree/master)  
