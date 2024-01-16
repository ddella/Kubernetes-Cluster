# Bind - Raspberry Pi 1
Clean up

```sh
sudo apt purge chromium*
sudo apt purge cups*
sudo apt purge gnome*
sudo apt purge vlc*
sudo apt purge gstreamer*
sudo apt purge gtk2*
sudo apt purge xserver* qt5* 
```

# Install Bind9
```sh
sudo apt-get install bind9 bind9utils dnsutils
```

```sh
cat <<EOF > /etc/bind/named.conf > /dev/null
// Managing acls
acl internals { 127.0.0.0/8; 192.168.13.0/24; 10.0.0.0/8; };

include "/etc/bind/named.conf.options";
include "/etc/bind/named.conf.local";
include "/etc/bind/named.conf.default-zones";
EOF
```

```sh
cat <<EOF | sudo tee /etc/bind/named.conf.local
zone "kloud.lan" IN {
  type master;
  file "/etc/bind/db.kloud.lan";
};
zone "13.168.192.in-addr.arpa" {
  type master;
  file "/etc/bind/db.rev.13.168.192.in-addr.arpa";
};
EOF
```
  
```sh
cat <<'EOF' | sudo tee /etc/bind/db.kloud.lan > /dev/null
$TTL    360
@       IN      SOA     dns.kloud.lan. root.kloud.lan. (
          2023092702           ; Serial
                3600           ; Refresh [1h]
                600           ; Retry   [10m]
              86400           ; Expire  [1d]
                600 )         ; Negative Cache TTL [1h]
;
@       IN      NS      dns.kloud.lan.

router        IN A 192.168.13.1
dns           IN A 192.168.13.10
k8smaster1    IN A 192.168.13.61
k8sworker1    IN A 192.168.13.65
k8sworker2    IN A 192.168.13.66
k8sworker3    IN A 192.168.13.67
EOF
```

```sh
cat <<'EOF' | sudo tee /etc/bind/db.rev.13.168.192.in-addr.arpa > /dev/null
$TTL    360
@       IN      SOA     dns.kloud.lan. root.kloud.lan. (
          2023092701           ; Serial
                3600           ; Refresh [1h]
                600           ; Retry   [10m]
              86400           ; Expire  [1d]
                600 )         ; Negative Cache TTL [1h]
;
@       IN      NS      dns.kloud.lan.

          IN NS dns.kloud.lan.
1         IN PTR router.kloud.lan.
61        IN PTR k8smaster1.kloud.lan.
65        IN PTR k8sworker1.kloud.lan.
66        IN PTR k8sworker2.kloud.lan.
67        IN PTR k8sworker3.kloud.lan.
EOF
```

```sh
cat <<EOF | sudo tee /etc/bind/named.conf.options > /dev/null
options {
  directory "/var/cache/bind";

  // Listen on local interfaces only(IPV4)
  listen-on {
    127.0.0.1;
    192.168.13.10;
  };

  // Do not transfer the zone information to the secondary DNS
  allow-transfer { none; };

  // Accept requests for internal network only
  allow-query { internals; };

  // Allow recursive queries to the local hosts
  //allow-recursion { internals; };

  // Do not make public version of BIND
  //version none;
};
EOF
```
