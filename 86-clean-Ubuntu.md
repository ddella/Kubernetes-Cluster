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

# List old Kernels
```sh
sudo dpkg --list | egrep 'linux-image|linux-headers'
sudo nala purge linux-headers-6.4.3-060403-generic
sudo nala purge linux-headers-6.4.3-060403
```
