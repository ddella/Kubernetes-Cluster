# Clone the VM
Since I'm using the standard version of Vmware Fusion I copied the VMs with Finder 😀 Now let's start the VM one by one and personalized them.

## Hostname and Domain Name
```sh
export MY_HOSTNAME=test2
export DOMAINNAME=kloud.lan
```

## Hostname
Change the hostname
```sh
sudo hostnamectl hostname "${MY_HOSTNAME}.${DOMAINNAME}"
```

Verify the change the has been apply:
```sh
sudo hostnamectl status
hostname -f
hostname -d
```

## Modify `/etc/hosts` file
```sh
sudo sed -i "s/127\.0\.1\.1.*/127.0.1.1 ${MY_HOSTNAME}/" /etc/hosts
```

## IP Address
To change the IP address, edit the file `00-installer-config.yaml`:
```sh
sudo vi /etc/netplan/00-installer-config.yaml
```

Or modify this and paste it in the terminal:
```sh
sudo tee /etc/netplan/00-installer-config.yaml<<EOF > /dev/null
# This is the network config written by 'subiquity'
network:
  version: 2
  renderer: networkd
  ethernets:
    ens18:
      dhcp4: false
      addresses:
      - 192.168.13.21/24
      nameservers:
        addresses:
        - 9.9.9.9
        - 149.112.112.112
        search:
        - isociel.com
      routes:
      - to: default
        via: 192.168.13.1
EOF
```

> [!IMPORTANT]  
> Set the permission on the file `00-installer-config.yaml ` or you will get the following warning message:

  ** (process:1163): WARNING **: 11:26:36.571: Permissions for /etc/netplan/00-installer-config.yaml are too open. Netplan configuration should NOT be accessible by others.

```sh
sudo chmod 600 /etc/netplan/00-installer-config.yaml
```

## SSH
Generate a new ECC SSH public/private key pair:
```sh
ssh-keygen -q -t ecdsa -N '' -f ~/.ssh/id_ecdsa <<<y >/dev/null 2>&1
```

# Generate `/etc/machine-id`
Regenerate the file `/etc/machine-id`. Just empty the file and reboot:
```sh
sudo cp /dev/null /etc/machine-id
```

# A start job is running for wait for network to be configured
If your ssystem takes a long time to boot and you get this annoying error message on the console: `A start job is running for wait for network to be configured`, enter the commands below:
```sh
sudo systemctl disable systemd-networkd-wait-online.service
sudo systemctl mask systemd-networkd-wait-online.service
```

-  disable the wait-online service to prevent the system from waiting on a network connection
-  prevent the service from starting, if requested by another service. The service is symlinked to `/dev/null`

# Shutdown
Just shutdown the VM or reboot and test it
```sh
sudo init 6
```
