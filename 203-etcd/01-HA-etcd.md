# Set up a High Availability etcd Cluster
`etcd` is distributed, reliable key-value store for the most critical data of a distributed system. It's a strongly consistent, distributed key-value store that provides a reliable way to store data that needs to be accessed by a distributed system or cluster of machines. It gracefully handles leader elections during network partitions and can tolerate machine failure, even in the leader node.

This tutorial is the instructions for installing `etcd` on a three-node cluster from pre-built binaries. This tutorial has nothing to do with Kubernetes. It could eventually be used when  installing an H.A Kubernetes Cluster with `External etcd` topology.

# Before you begin
We will be using three Ubuntu Server 22.04.3 with Linux Kernel 6.4.12

- Three hosts that can talk to each other over TCP port `2380`.
- The clients of the `etcd` cluster can reach any of them on TCP port `2379`.
  - TCP ports `2379` is the secure traffic for client requests
  - TCP ports `2380` is the secure traffic for server-to-server communication
- Each host must have `systemd` and a `bash` compatible shell installed.
- Some infrastructure to copy files between hosts. For example `ssh` and `scp` can satisfy this requirement.

# Setup an External ETCD Cluster
In this tutorial we will configure a three-node TLS enabled `etcd` cluster that can act as an external datastore for a H.A. software, like a Kubernetes H.A. Cluster 😉

|Role|FQDN|IP|OS|Kernel|RAM|vCPU|
|----|----|----|----|----|----|----|
|etcd|k8setcd1.isociel.com|192.168.13.35|Ubuntu 22.04.3|6.4.12|2G|2|
|etcd|k8setcd2.isociel.com|192.168.13.36|Ubuntu 22.04.3|6.4.12|2G|2|
|etcd|k8setcd3.isociel.com|192.168.13.37|Ubuntu 22.04.3|6.4.12|2G|2|

![ETCD Cluster](images/k8s-cluster.jpg)

# Download the binaries
Install the latest version of the binaries on each of the three Linux host.

> [!NOTE]  
> `etcdctl` is a command line tool for interacting with the `etcd` database(s) in a cluster.

## Install ETCD from binaries
```sh
export VER=$(curl -s https://api.github.com/repos/etcd-io/etcd/releases/latest|grep tag_name | cut -d '"' -f 4)
echo ${VER}
curl -LO https://github.com/etcd-io/etcd/releases/download/${VER}/etcd-${VER}-linux-amd64.tar.gz
tar xvf etcd-${VER}-linux-amd64.tar.gz
cd etcd-${VER}-linux-amd64
sudo cp etcdctl etcdutl etcd /usr/local/bin/
sudo chown root:adm /usr/local/bin/etcdctl /usr/local/bin/etcdutl /usr/local/bin/etcd
```

## Verify installation
```sh 
etcdctl version
etcdutl version
```

## Cleanup
```sh
cd ..
rm -rf etcd-${VER}-linux-amd64
rm etcd-${VER}-linux-amd64.tar.gz
unset VER
```

# Generating and Distributing TLS Certificates
We will use the `Openssl` tool to generate our own CA and all the `etcd` server certificates and keys.

## Generate Private CA
```sh
./11-ecc_gen_chain.sh
```

This results in two files
- `etcd-ca.crt` is the CA certificate
- `etcd-ca.key` is the CA private key

## Generate Server Certificates
We will generate the certificate and key for every `etcd` node in the cluster. Delete the `csr` files as they are not needed anymore:
```sh
./12-gen_cert.sh k8setcd1 192.168.13.35 etcd-ca
./12-gen_cert.sh k8setcd2 192.168.13.36 etcd-ca
./12-gen_cert.sh k8setcd3 192.168.13.37 etcd-ca
rm -f *.csr
```

This results in two files for each `etcd` node. The `.crt` is the certificate and the `.key` is the private key:
- k8setcd1.crt
- k8setcd1.key
- k8setcd2.crt
- k8setcd2.key
- k8setcd3.crt
- k8setcd3.key

> [!IMPORTANT]  
> The private keys are not encrypted as `etcd` needs a non-encrypted `pem` file.

At this point, we have the certificates and keys generated for the CA and all the three nodes. The nodes certifcate has a SAN with the hostname, FQDN and IP address. See example below for node `k8setcd1`
- DNS:k8setcd1
- DNS:k8setcd1.isociel.com
- IP Address:192.168.13.35

# Distribute Certificates
We need to to distribute these certificates and keys to each `etcd` node in the cluster. I've made a script. Adusts the nodes and execute.
```sh
./13-scp.sh
```

# Move Certificate and Key
SSH into each node and run the below commands to move the certificate and key into the `/etc/etcd/pki` directory. I will be using `tmux` to run the commands on every node at the same time. Just paste the following in each node. The certificates and keys have the short hostname and the variable `ETCD_NAME` will be different on each node.
```sh
ETCD_NAME=$(hostname -s)
sudo mkdir -p /etc/etcd/pki
sudo mv etcd-ca.crt /etc/etcd/pki/.
sudo mv ${ETCD_NAME}.{crt,key} /etc/etcd/pki/.
sudo chmod 600 /etc/etcd/pki/${ETCD_NAME}.key
```

We have generated and copied all the certificates/keys on each node. In the next step, we will create the configuration file and the `systemd` unit file for each node.

# Create `etcd` configuration file
This is the configuration file `/etc/etcd/etcd.conf` that needs to be copied on each node. The command can be pasted simultaneously on all the nodes. I will be using `tmux`:
```sh
ETCD_CLUSTER_NAME=etcd-cluster-1
ETCD_IP=$(hostname -i)
ETCD_NAME=$(hostname -s)
ETCD1_IP=192.168.13.35
ETCD2_IP=192.168.13.36
ETCD3_IP=192.168.13.37

cat <<EOF | sudo tee /etc/etcd/etcd.conf > /dev/null
# Human-readable name for this member.
name: "${ETCD_NAME}"

# List of comma separated URLs to listen on for peer traffic.
listen-peer-urls: "https://${ETCD_IP}:2380"

# List of comma separated URLs to listen on for client traffic.
listen-client-urls: "https://${ETCD_IP}:2379,https://127.0.0.1:2379"

# List of additional URLs to listen on that will respond to both the /metrics and /health endpoints
listen-metrics-urls: "http://${ETCD_IP}:2381"

# Initial cluster token for the etcd cluster during bootstrap.
initial-cluster-token: o3ZBeUqBgjAMArh8c5BQmuK

# Comma separated string of initial cluster configuration for bootstrapping.
initial-cluster: "k8setcd1=https://${ETCD1_IP}:2380,k8setcd2=https://${ETCD2_IP}:2380,k8setcd3=https://${ETCD3_IP}:2380"

# List of this member's peer URLs to advertise to the rest of the cluster.
# The URLs needed to be a comma-separated list.
initial-advertise-peer-urls: "https://${ETCD_IP}:2380"

# List of this member's client URLs to advertise to the public.
# The URLs needed to be a comma-separated list.
advertise-client-urls: "https://${ETCD_IP}:2379,https://127.0.0.1:2379"

client-transport-security:
  # Path to the client server TLS cert file.
  cert-file: "/etc/etcd/pki/${ETCD_NAME}.crt"

  # Path to the client server TLS key file.
  key-file: "/etc/etcd/pki/${ETCD_NAME}.key"

  # Path to the client server TLS trusted CA cert file.
  trusted-ca-file: "/etc/etcd/pki/etcd-ca.crt"

  # Enable client cert authentication.
  client-cert-auth: true

peer-transport-security:
  # Path to the peer server TLS cert file.
  cert-file: "/etc/etcd/pki/${ETCD_NAME}.crt"

  # Path to the peer server TLS key file.
  key-file: "/etc/etcd/pki/${ETCD_NAME}.key"

  # Enable peer client cert authentication.
  client-cert-auth: true

  # Path to the peer server TLS trusted CA cert file.
  trusted-ca-file: "/etc/etcd/pki/etcd-ca.crt"

# Path to the data directory.
data-dir: "/var/lib/etcd"

# Initial cluster state ('new' or 'existing').
initial-cluster-state: 'new'
EOF
```

> [!IMPORTANT]  
> Any locations specified by `listen-metrics-urls` will respond to the `/metrics` and `/health` endpoints in `http` only.
> This can be useful if the standard endpoint is configured with mutual (client) TLS authentication (`listen-client-urls: "https://...`), but a load balancer or monitoring service still needs access to the health check with `http` only.
> The endpoint `listen-client-urls` still answers to `https://.../metrics`.

# Configuring and Starting the `etcd` Cluster
On every node, create the file `/etc/systemd/system/etcd.service` with the following contents. I will be using `tmux`:
```sh
cat <<EOF | sudo tee /lib/systemd/system/etcd.service
[Unit]
Description=etcd key-value store service
Documentation=https://github.com/etcd-io/etcd
After=network.target
 
[Service]
Type=notify
ExecStart=/usr/local/bin/etcd --config-file /etc/etcd/etcd.conf
Restart=always
RestartSec=5s
LimitNOFILE=40000
 
[Install]
WantedBy=multi-user.target
EOF
```

# Start `etcd` service

```sh
sudo systemctl daemon-reload
sudo systemctl enable --now etcd
sudo systemctl status etcd
```

# Testing and Validating the Cluster
To interact with the cluster we will be using `etcdctl`. It's the utility to interact with the `etcd` cluster. This utility as been installed in `/usr/local/bin` on three nodes and I also installed it on a bastion host.

> [!NOTE]  
> Unless otherwise specified, all the `etcdctl` commands are run from a bastion host.

You can export these environment variables and connect to the clutser without specifying the values each time:
```sh
export ETCDCTL_API=3
export ETCDCTL_ENDPOINTS=https://k8setcd1:2379,https://k8setcd2.isociel.com:2379,https://192.168.13.37:2379
export ETCDCTL_CACERT=./etcd-ca.crt
export ETCDCTL_CERT=./k8setcd1.crt
export ETCDCTL_KEY=./k8setcd1.key
```

## Check Cluster status
To execute the next command, you can be on any host that:
- can reach the `etcd` servers on port `TCP/2379`
- has the client certificate, the CA sertificate and private key

And now its a lot easier
```sh
etcdctl --write-out=table member list
etcdctl --write-out=table endpoint status
etcdctl --write-out=table endpoint health
```

See below for the ouput of the three commands above:
```
etcdctl --write-out=table member list
+------------------+---------+----------+----------------------------+---------------------------------------------------+------------+
|        ID        | STATUS  |   NAME   |         PEER ADDRS         |                   CLIENT ADDRS                    | IS LEARNER |
+------------------+---------+----------+----------------------------+---------------------------------------------------+------------+
|  16ad12f4a1f549a | started | k8setcd1 | https://192.168.13.35:2380 | https://127.0.0.1:2379,https://192.168.13.35:2379 |      false |
| 50740e0c08a5f503 | started | k8setcd3 | https://192.168.13.37:2380 | https://127.0.0.1:2379,https://192.168.13.37:2379 |      false |
| 8c5e7dd3a9c00dca | started | k8setcd2 | https://192.168.13.36:2380 | https://127.0.0.1:2379,https://192.168.13.36:2379 |      false |
+------------------+---------+----------+----------------------------+---------------------------------------------------+------------+
```

```
etcdctl --write-out=table endpoint status
+-----------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|             ENDPOINT              |        ID        | VERSION | DB SIZE | IS LEADER | IS LEARNER | RAFT TERM | RAFT INDEX | RAFT APPLIED INDEX | ERRORS |
+-----------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
|             https://k8setcd1:2379 |  16ad12f4a1f549a |   3.5.9 |   20 kB |     false |      false |         9 |         66 |                 66 |        |
| https://k8setcd2.isociel.com:2379 | 8c5e7dd3a9c00dca |   3.5.9 |   20 kB |      true |      false |         9 |         66 |                 66 |        |
|        https://192.168.13.37:2379 | 50740e0c08a5f503 |   3.5.9 |   20 kB |     false |      false |         9 |         66 |                 66 |        |
+-----------------------------------+------------------+---------+---------+-----------+------------+-----------+------------+--------------------+--------+
```

```
etcdctl --write-out=table endpoint health
+-----------------------------------+--------+--------------+-------+
|             ENDPOINT              | HEALTH |     TOOK     | ERROR |
+-----------------------------------+--------+--------------+-------+
|        https://192.168.13.37:2379 |   true |  34.222735ms |       |
| https://k8setcd2.isociel.com:2379 |   true |  52.158893ms |       |
|             https://k8setcd1:2379 |   true | 121.486991ms |       |
+-----------------------------------+--------+--------------+-------+
```

>For the `--endpoints`, enter all of your nodes and test with the short hostname, FQDN and IP address.

## Check the logs
> [!NOTE]  
> You need to be on an `etcd` host to execute the following command:

Check for any warnings/errors on every nodes:
```sh
journalctl -xeu etcd.service
```

## Write and Read test

**STEP1:** Write a value on one node:
```sh
etcdctl put foo "Hello World!"
```

**STEP2:** Read the data back from a different node:
```sh
etcdctl get foo
etcdctl --write-out="json" get foo
```

## Test with `cURL`
Not very usefull. Use `etcdctl` and `etcdutl`.
```sh
ENDPOINT1='https://192.168.13.36:2379'
curl -v --cacert ./etcd-ca.crt --cert ./k8setcd1.crt --key ./k8setcd1.key \
-L ${ENDPOINT1}/v3/kv/range -X POST -d '{"key":"L3B1Yi9hYWFh"}'
```

## Test Metrics
```sh
METRIC='http://192.168.13.36:2381'
curl -L ${METRIC}/metrics
```

`/health` endpoint also works:
```sh
METRIC='http://192.168.13.36:2381'
curl -L ${METRIC}/health
```

# Congratulation
You should have a three-node `etcd` cluster in **High Availibility** mode 🍾🎉🥳

# References
[Set up a High Availability etcd Cluster with kubeadm](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/setup-ha-etcd-with-kubeadm/)  
[Options for Highly Available Topology](https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/ha-topology/)  
[Configuration file for etcd server](https://github.com/etcd-io/etcd/blob/main/etcd.conf.yml.sample)  

---
My goal is to incorporate this above tutorial with configuring an H.A. Kubernetes Cluster.

# Options for Highly Available Topology
You can set up an HA cluster:

- With stacked control plane nodes, where `etcd` nodes are colocated with control plane nodes
- With external `etcd` nodes, where `etcd` runs on separate nodes from the control plane

You should carefully consider the advantages and disadvantages of each topology before setting up an HA cluster.

## Stacked ETCD topology
A stacked HA cluster is a topology where the distributed data storage cluster provided by `etcd` is stacked on top of the cluster formed by the nodes managed by `kubeadm` that run control plane components.

Each control plane node runs an instance of the `kube-apiserver`, `kube-scheduler`, and `kube-controller-manager`. The `kube-apiserver` is exposed to worker nodes using a load balancer.

Each control plane node creates a local `etcd` member and this `etcd` member communicates only with the `kube-apiserver` of this node.

This topology couples the control planes and `etcd` members on the same nodes.

However, a stacked cluster runs the risk of failed coupling. If one node goes down, both an `etcd` member and a control plane instance are lost, and redundancy is compromised.

You should therefore run a minimum of three stacked control plane nodes for an HA cluster.

![stacked](images/kubeadm-ha-topology-stacked-etcd.jpg)

## External ETCD topology

An HA cluster with external `etcd` is a topology where the distributed data storage cluster provided by `etcd` is external to the cluster formed by the nodes that run control plane components.

Like the stacked `etcd` topology, each control plane node in an external `etcd` topology runs an instance of the `kube-apiserver`, `kube-scheduler`, and `kube-controller-manager`. And the `kube-apiserver` is exposed to worker nodes using a load balancer. However, `etcd` members run on *separate hosts*, and each `etcd` host communicates with the `kube-apiserver` of every control plane node.

This topology decouples the control plane and `etcd` member. It therefore provides an HA setup where losing a control plane instance or an `etcd` member has less impact and does not affect the cluster redundancy as much as the stacked HA topology.

However, this topology requires twice the number of hosts as the stacked HA topology. A minimum of three hosts for control plane nodes and three hosts for `etcd` nodes are required for an HA cluster with this topology.

![external](images/kubeadm-ha-topology-external-etcd.jpg)