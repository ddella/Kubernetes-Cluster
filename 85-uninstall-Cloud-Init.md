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

# Disable Service
Disabling the service is the easiest and safest way if you’re considering using it in the future.

```sh
sudo touch /etc/cloud/cloud-init.disabled
sudo init 6
```

# References
[Remove Cloud-Init from Ubuntu 22.04 LTS](https://notes.n3s0.tech/posts/20221208145448/)  
