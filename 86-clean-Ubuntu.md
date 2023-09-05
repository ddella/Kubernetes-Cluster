# Cleanup Ubu0ntu 22.04

```sh
sudo nala autoremove --purge
sudo apt-get autoclean
journalctl --disk-usage
sudo journalctl --vacuum-time=3d
```

# Check packages
```sh
dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -nr | head -20
```

# List Kernels
List all Kernels installed on the system:
```sh
sudo dpkg --list | egrep 'linux-image|linux-headers|linux-modules'
```

## Cleanup
Before cleaning the old Kernels, update the system and reload:
```sh
sudo nala update && sudo nala upgrade
sudo init 6
```

Clean the old kernels with:
```sh
sudo nala purge -y linux-headers-6.4.12-060412-generic
sudo nala purge -y linux-headers-6.4.12-060412
sudo nala purge -y linux-image-unsigned-6.4.12-060412-generic
sudo nala purge -y linux-modules-6.4.12-060412-generic
```

---

# Deleting `netplan`
I don't know what happened but I deleted `netplan` by mistake. No need to tell you that without networking you can install `netplan` 😉

Here's what I did to to recover my server:
```sh
sudo ip address add 192.168.13.xx/24 dev ens33
sudo ip link set ens33 up
sudo ip route add default via 192.168.13.1
# Add a DNS
sudo vi /etc/resolv.conf
sudo apt install netplan.io
```
