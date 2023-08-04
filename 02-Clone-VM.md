# Clone the VM
Since I'm using the standard version of Vmware Fusion I copied the VMs with Finder 😀 Now let's start the VM one by one and personalized them.

## Hostname and Domain Name
```sh
export MY_HOSTNAME=k8sworker1
export DOMAINNAME=isociel.com
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

## SSH
Generate a new ECC SSH public/private key pair:
```sh
ssh-keygen -q -t ecdsa -N '' -f ~/.ssh/id_ecdsa <<<y >/dev/null 2>&1
```

# Shutdown
Just shutdown the VM or reboot and test it
```sh
sudo init 6
```
