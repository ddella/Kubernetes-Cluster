# What is Nala
Nala is a front-end for libapt-pkg. Specifically we interface using the python-apt api.

Especially for newer users it can be hard to understand what apt is trying to do when installing or upgrading.

We aim to solve this by not showing some redundant messages, formatting the packages better, and using color to show specifically what will happen with a package during install, removal, or an upgrade.

# Download the following packages:

```sh
curl -LO https://gitlab.com/volian/volian-archive/uploads/b20bd8237a9b20f5a82f461ed0704ad4/volian-archive-keyring_0.1.0_all.deb
curl -LO https://gitlab.com/volian/volian-archive/uploads/d6b3a118de5384a0be2462905f7e4301/volian-archive-nala_0.1.0_all.deb
```

# Install the archive packages:
```sh
sudo apt install ./volian-archive*.deb
```

# Ubuntu 22.04
After the repository and key are installed simply run

```sh
sudo apt update && sudo apt install nala
```

# Update
```sh
sudo nala update
```

# Update
```sh
nala list --upgradable
```
