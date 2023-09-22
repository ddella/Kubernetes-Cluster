# Ubuntu 22.04 LTS (Jammy) - `debootstrap`
This tutorial is about how to install a very lean image of Ubuntu, without any GUI or any other useless software packages. This should be my base Ubuntu image for Kubernetes Cluster.

# Find your device
I used an already running Ubuntu Server 22.04 LTS. In Vmware I added a seperate disk. My main disk for the running OS is on `/dev/sda` and the new drive that I added came in as `/dev/sdb`. That's the one we will work on.

My output of `lsblk`, yours might vary:
```
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   20G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 18.2G  0 part 
  └─ubuntu--vg-ubuntu--lv 253:0    0   10G  0 lvm  /
sdb                         8:16   0   20G  0 disk  <------ New disk for this demo
sr0                        11:0    1 1024M  0 rom  
```

Set some environment variable
```sh
export BLK_DEVICE='/dev/sdb'
export BLK_DEVICE_BOOT='/dev/sdb1'
export BLK_DEVICE_ROOT='/dev/sdb2'
```

# Create the disk
Let's start by creating two new partitions and file systems on the new drive.

## Install `parted`
```sh
sudo apt update && sudo apt -y install parted debootstrap
```

## Partitions
Created with `fdisk`

Partition | Mount point | Format | Size   | Flags    |
----------|-------------|--------|--------|----------
/dev/sdb1 | /boot/efi   | VFAT   | 512 MB | boot, esp|
/dev/sdb2 | /           | EXT4   |    max | (n/a)    |

Use `fdisk` to perform the partitioning of the drive.

1. Create a new GPT partition table.
2. Create a new partition of 512MB.
3. Set it to EFI.
4. Create the main partition with the left-over space as a regular Linux filesystem.
5. Finally, write the changes to the disk.

```sh
sed -e 's/\s*\([\+0-9a-zA-Z]*\).*/\1/' << EOF | sudo fdisk ${BLK_DEVICE}
g # Create new GPT label
n # new partition
1 # partition number 1 
    # default - start at beginning of disk
+512M # 512 MB boot partition
t # change type
1 # EFI partition
n # new partition
2 # partion number 2
    # default, start immediately after preceding partition
    # default, extend partition to end of disk
w # write the partition table
EOF
```

Check the results with `lsblk`
```
NAME                      MAJ:MIN RM  SIZE RO TYPE MOUNTPOINTS
sda                         8:0    0   20G  0 disk 
├─sda1                      8:1    0    1M  0 part 
├─sda2                      8:2    0  1.8G  0 part /boot
└─sda3                      8:3    0 18.2G  0 part 
  └─ubuntu--vg-ubuntu--lv 253:0    0   10G  0 lvm  /
sdb                         8:16   0   20G  0 disk 
├─sdb1                      8:17   0  512M  0 part 
└─sdb2                      8:18   0 19.5G  0 part 
sr0                        11:0    1 1024M  0 rom  
```

## CREATE PARTITION TABLE AND CREATE PARTITION
```sh
sudo parted --script ${BLK_DEVICE} mklabel gpt
sudo parted -a optimal ${BLK_DEVICE} mkpart primary fat32 0% 512MB
sudo parted -a optimal ${BLK_DEVICE} mkpart primary ext4 512MB 100%
# This flag identifies a UEFI System Partition. On GPT it' i's an alias for boot.
sudo parted ${BLK_DEVICE} set 1 esp on
```

Format the EFI partition as `FAT32` and the main partition as `ext4`. Use `lsblk` to get the device name.
```sh
sudo mkfs.vfat ${BLK_DEVICE_BOOT}
yes y | sudo mkfs.ext4 ${BLK_DEVICE_ROOT}
```

# Mount Partitions
1. Mount the root partition.
2. Create a directory for `/boot/efi`.
3. Mount the EFI partition.

```sh
sudo mount ${BLK_DEVICE_ROOT} /mnt
sudo mkdir -p /mnt/boot/efi
sudo mount ${BLK_DEVICE_BOOT} /mnt/boot/efi
```

# Start the installation
Install the base system and some tools:
```sh
# sudo debootstrap --variant=minbase \
sudo debootstrap \
--include grub-efi,locales,curl,wget,gnupg2,vim \
--arch=amd64 jammy /mnt
```

> [!NOTE]  
> This will take some time to complete.

# Setting apt sources
Copy the `/etc/apt/source.list` on the new system and remove all references to the local `CD-ROM`.

```sh
sudo cp /etc/apt/sources.list /mnt/etc/apt/.
```

# Disable Package (Optional)

```sh
cat << EOF > /etc/apt/preferences.d/99-disabled
Package: snapd
Pin: release *
Pin-Priority: -1

Package: unattended-upgrades
Pin: release *
Pin-Priority: -1

Package: apport
Pin: release *
Pin-Priority: -1
EOF
```

# Edit `fstab`
We need to edit the file `/etc/fstab`. You can do it manually but this is prone to error. Having a wrong `/etc/fstab` will make the system unavailable. To make sure we're not making any error, let's use `genfstab` from the package `arch-install-scripts` to generate the file for us. The package can be installed through `apt`.

1. Install scripts
2. Run `genfstab` on `/mnt` to generate the `/etc/fstab` file.

```sh
# Package size is only 52Kb
sudo apt -y install arch-install-scripts
sudo genfstab -U /mnt | sudo tee /mnt/etc/fstab
```

# Prepare the chroot environment
1. Copy `/etc/resolv.conf`
2. Bind virtual file systems.
3. Changing root to the new system

```sh
sudo cp /etc/resolv.conf /mnt/etc/.
for d in sys dev proc ; do sudo mount --rbind /$d /mnt/$d && sudo mount --make-rslave /mnt/$d ; done
sudo chroot /mnt /bin/bash
```

> [!WARNING]  
> If you don't mount the `dev` above, you will get this error message: `unable to allocate pty: No such device`

# Upgrade
Upgrade the new system.
```sh
apt update && apt -y upgrade
```

# Setting timezone and locale
1. Set timezone
2. Set locale
3. Set root password
4. Create normal user
5. Set password for normal user
6. Add normal user to `sudo` group

```sh
sudo ln -fs /usr/share/zoneinfo/America/Montreal /etc/localtime
echo "en_US.UTF-8 UTF-8" | sudo tee -a /etc/locale.gen
sudo locale-gen
useradd daniel -m -c "Dan" -s /bin/bash
usermod -aG sudo daniel
passwd daniel
```

# Do I need this???
```sh
cat <<EOF | sudo tee /etc/kernel-img.conf > /dev/null
#do_symlinks=no
#no_symlinks=yes
EOF
```

# Install Packages
```sh
apt -y install linux-image-generic network-manager intel-microcode
```

# Setting up bootloader

1. Install
2. Install GRUB.
3. generate GRUB configs.

```sh
# sudo apt install grub-efi-amd64
sudo grub-install --target=x86_64-efi --efi-directory=/boot/efi --bootloader=Ubuntu
# sudo update-grub2
```

# Network
```sh
sudo echo "bastion1" > /etc/hostname
echo "127.0.1.1    bastion1.localdomain bastion1" | sudo tee - /etc/hosts
systemctl enable NetworkManager
sudo apt install -y openssh-server
```

Or modify this and paste it in the terminal:
```sh
# mkdir -p /etc/netplan/
cat <<EOF | sudo tee /etc/netplan/00-installer-config.yaml > /dev/null
# This is the network config written by 'subiquity'
network:
  version: 2
  renderer: networkd
  ethernets:
    ens33:
      dhcp4: false
      addresses:
      - 192.168.13.29/24
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

# Fix errors
They were some annoimg errors that I was able to fix.

## Terminal Console
To fix the errors:
```
error: no server is specified
error: no suitable video mode found
```

Enter the following commands:
```sh
sudo sed -i 's/#GRUB_TERMINAL=console/GRUB_TERMINAL=console/' /etc/default/grub
sudo update-grub2
```

### Bluetooth error
I also had this error on boot screen:
```
Bluetooth: hci0: Opcode 0x c12 failed: -38
```

I uncheck the option in Vmware Fusion: `Share Bluetooth devices with Linux`

## SMBus base error
To fix the error `SMBus base address uninitialized - upgrade bios or use force_addr=0xaddr`:
```sh
sudo echo "blacklist i2c_piix4" | sudo tee -a /etc/modprobe.d/blacklist.conf
sudo update-initramfs -u -k all
```

# Cleanup
1. Leave `chroot`
2. Unmount everything
3. Reboot

```sh
exit
sudo umount -a
sudo init 0
```

# References
https://www.youtube.com/watch?v=UumkGuoy0tk
https://myterminal.me/diary/20210724/(VIDEO)-Installing-a-Minimal-Debian-system-the-Arch-way

---
# Create a new VM
Create a new VM with the disk we just created.

> [!IMPORTANT]  
> Make sure you configure your network correctly. In my case I needed to use `Vmware Bridge Network`.

# After reboot

### sudo (Optional)
If you want to use `sudo` without password, enter that command (use wisely, that can be dangerous 😉):
```sh
echo "${USER} ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${USER} > /dev/null
```

**THIS COMMAND IS EXECUTED FROM YOUR PC/BASTION HOST, NOT FROM THE NEW UBUNTU VM**
Replace the IP `192.168.13.xx` with the address of the new Ubuntu server:
```sh
ssh-copy-id -i ~/.ssh/id_ecdsa.pub 192.168.13.xx
```

## Latest Kernel
```sh
# sudo apt install -y curl wget gnupg2
curl -LO https://raw.githubusercontent.com/pimlie/ubuntu-mainline-kernel.sh/master/ubuntu-mainline-kernel.sh
chmod +x ubuntu-mainline-kernel.sh
sudo mv ubuntu-mainline-kernel.sh /usr/local/bin/
sudo chown -R root:adm /usr/local/bin/
sudo ubuntu-mainline-kernel.sh -i v6.5.3
```

Reboot with the new Kernel:
```sh
sudo init 6
```

### Delete the old kernels to free disk space
```sh
sudo apt --fix-broken -y install
sudo dpkg --list | egrep 'linux-image|linux-headers|linux-modules'
```

Remove old kernels listing from the preceding step with the command (adjust the image name):
```sh
sudo apt -y purge $(dpkg-query --show 'linux-image-*' | cut -f1 | grep -v "$(uname -r | cut -f1 -d '-')")
sudo apt -y purge $(dpkg-query --show 'linux-headers-*' | cut -f1 | grep -v "$(uname -r | cut -f1 -d '-')")
sudo apt -y purge $(dpkg-query --show 'linux-modules-*' | cut -f1 | grep -v "$(uname -r | cut -f1 -d '-')")
sudo apt -y autoremove
sudo update-grub2
```

# Remove wpa_supplicant

```sh
sudo apt -y autoremove wpasupplicant
```

# Remove modemmanager

```sh
sudo apt -y autoremove modemmanager
```

# Install IPVS

```sh
sudo apt update
sudo apt -y install ipvsadm ipset

cat <<EOF | sudo tee /etc/modules-load.d/ipvs.conf > /dev/null
ip_vs
ip_vs_rr
ip_vs_wrr
ip_vs_sh
nf_conntrack
EOF

sudo systemctl restart systemd-modules-load.service
sudo systemctl status systemd-modules-load.service
```
