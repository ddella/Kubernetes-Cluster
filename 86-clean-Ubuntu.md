# Cleanup Ubuntu 22.04 LTS

## Check packages
```sh
dpkg-query -Wf '${Installed-Size}\t${Package}\n' | sort -nr | head -20
```

## System Journal
Check the System Journal log size:
```sh
journalctl --disk-usage
```

Reduce log size to 50 MB. This is a one-time action:
```sh
sudo journalctl --vacuum-time=50m
```

Make it permanent:
```sh
sudo sed -i 's/#SystemMaxUse=/SystemMaxUse=50M/' /etc/systemd/journald.conf
sudo sed -i 's/#SystemMaxFiles=100/SystemMaxFiles=5/g' /etc/systemd/journald.conf
sudo journalctl --rotate
```

```sh
# keep 1 week worth of backlogs
sudo sed -i 's/rotate 4/rotate 1/g' /etc/logrotate.conf
# rotate log files daily
sudo sed -i 's/weekly/daily/g' /etc/logrotate.conf
```

## Cleanup Kernels
List all Kernels installed on the system:
```sh
sudo dpkg --list | egrep 'linux-image|linux-headers|linux-modules'
```

Before cleaning the old Kernels, update the system and reload:
```sh
sudo nala update && sudo nala upgrade
sudo init 6
```

Clean the old kernels with:
```sh
sudo nala purge $(dpkg-query --show 'linux-image-*' | cut -f1 | grep -v "$(uname -r | cut -f1 -d '-'))")
sudo nala purge $(dpkg-query --show 'linux-headers-*' | cut -f1 | grep -v "$(uname -r | cut -f1 -d '-')")
sudo nala purge $(dpkg-query --show 'linux-modules-*' | cut -f1 | grep -v "$(uname -r | cut -f1 -d '-')")
```

## Check Services
Check for unwanted services:
```sh
service --status-all
```

# Remove Cloud-Init from Ubuntu 22.04 LTS
Those are the commands to completly remove Cloud init.

I generally removed Cloud Init because it started to give me some warning at boot time and I don’t use it with a Kubernetes Cluster.

```sh
# Uninstall and purge cloud-init from the server or workstation.
sudo apt purge cloud-init
# Remove the /etc/cloud/ directory.
sudo rm -rf /etc/cloud/
# Remove the /var/lib/cloud/ directory.
sudo rm -rf /var/lib/cloud/
# Reboot the system
sudo init 6
```

## Disable Service
Disabling the service is the easiest and safest way if you’re considering using it in the future.

```sh
sudo touch /etc/cloud/cloud-init.disabled
sudo init 6
```

# Remove Snap
```sh
sudo apt purge --auto-remove snapd
```

# Remove unattended upgrades [CAUTION]
> [!IMPORTANT]  
> Don't do this unless you **KNOW** what you are doing and the impacts.

This removes the `unattended-upgrades` package and the associated services which are reponsible for automatically updating packages in the system.
```sh
sudo apt purge --auto-remove unattended-upgrades
sudo systemctl disable apt-daily-upgrade.timer
sudo systemctl mask apt-daily-upgrade.service
sudo systemctl disable apt-daily.timer
sudo systemctl mask apt-daily.service
```

Comment `unattended-upgrades` that you judge unnecessary.
```sh
sudo vim /etc/apt/apt.conf.d/50unattended-upgrades
```

# Remove orphan packages
```sh
sudo nala autoremove --purge
sudo apt-get autoclean
```

# References
[Remove Cloud-Init from Ubuntu 22.04 LTS](https://notes.n3s0.tech/posts/20221208145448/)  

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
