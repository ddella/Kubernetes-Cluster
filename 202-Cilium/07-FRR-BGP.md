# FRR
FRRouting (FRR) is a free and open source Internet routing protocol suite for Linux and Unix platforms. It implements BGP, OSPF, RIP, IS-IS, PIM, LDP, BFD, Babel, PBR, OpenFabric and VRRP, with alpha support for EIGRP and NHRP.

FRR's seamless integration with native Linux/Unix IP networking stacks makes it a general purpose routing stack applicable to a wide variety of use cases including connecting hosts/VMs/containers to the network, advertising network services, LAN switching and routing, Internet access routers, and Internet peering.

FRR has its roots in the Quagga project. In fact, it was started by many long-time Quagga developers who combined their efforts to improve on Quagga's well-established foundation in order to create the best routing protocol stack available. We invite you to participate in the FRRouting community and help shape the future of networking.

# FRR
In this tutorial we will focus on how to install FRR on Ubuntu distro.

# Install FRR
Follow theses steps to install FRR on Debian/Ubuntu system:
```sh
# add GPG key
curl -s https://deb.frrouting.org/frr/keys.gpg | sudo tee /usr/share/keyrings/frrouting.gpg > /dev/null

# possible values for FRRVER: frr-stable frr-8 frr-8
# frr-8 will be the latest release
FRRVER="frr-stable"
echo deb '[signed-by=/usr/share/keyrings/frrouting.gpg]' https://deb.frrouting.org/frr $(lsb_release -s -c) $FRRVER | sudo tee -a /etc/apt/sources.list.d/frr.list

# update and install FRR
sudo apt update && sudo apt install frr frr-pythontools
```

### Linux Routing
If you didn't already activate routing:
```sh
cat <<EOF | sudo tee /etc/sysctl.d/20-routing-sysctl.conf
# Enable IP forwarding 
net.ipv4.conf.all.forwarding=1
# net.ipv6.conf.all.forwarding=1
EOF
```

# FRR Status
Check the status of FRR. It should be started and enabled:
```sh
sudo systemctl status frr
```

# Activate BGP
In this example I will activate only BGP:
```sh 
sudo sed -i 's/bgpd=no/bgpd=yes/' /etc/frr/daemons
sudo systemctl restart frr
sudo systemctl status frr
```

# Enjoy
Let's do a very basic BGP configuration. You can start a `Cisco like` shell with the command:
```sh
sudo vtysh 
```

### Simple BGP configuration
Here's a simple configuration. The prefix `192.0.2.0/24` is for testing only.

```
ip route 192.0.2.0/24 Null0
!
router bgp 65000
 neighbor 192.168.13.61 remote-as 65001
 !
 address-family ipv4 unicast
  network 192.0.2.0/24
  neighbor 192.168.13.61 soft-reconfiguration inbound
  neighbor 192.168.13.61 prefix-list INPUTALL in
  neighbor 192.168.13.61 prefix-list OUTPUTALL out
 exit-address-family
exit
!
ip prefix-list INPUTALL seq 5 permit any
ip prefix-list OUTPUTALL seq 5 permit any
```

# Config file
Your configuration is in file `/etc/frr/frr.conf`:
```sh
sudo cat /etc/frr/frr.conf
```

# References
[FRR Web Site](https://frrouting.org/)  
[GitHub](https://github.com/FRRouting/FRR)  
[FRR Debian/Ubuntu](https://deb.frrouting.org/)  
