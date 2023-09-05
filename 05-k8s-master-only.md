# Kubernetes High Availability(HA)
Kubernetes High Availability (HA) cluster uses multiple master nodes, each of which has access to same worker nodes. In a single master cluster the important component like API server, controller manager lies only on the single master node and if it fails you cannot create more services, pods etc. However, in case of Kubernetes HA environment, these important components are replicated on multiple masters (usually three masters) and if any of the masters fail, the other masters keep the cluster up and running.

Each master node, in a multi-master environment, runs its own copy of Kube API server and runs its own copy of the etcd database. In addition to API server and etcd database, the master node also runs k8s controller manager, which handles replication and scheduler, which schedules pods to nodes.

# Bootstrap a master node
The preferred way to configure `kubeadm` is to pass an YAML configuration file with the `--config` option. Some of the configuration options defined in the `kubeadm` config file are also available as command line flags, but only the most common/simple use case are supported with this approach.

You can use this procedure even if you plan to bootstrap only one Control Plane.

See [kubeadm Configuration (v1beta3)](https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/) for the options of the kubeadm configuration file format.

## Single Control Plane
If you plan to bootstrap only one Control Plane for now, I strongly suggest that you use a separate DNS entry for the `controlPlaneEndpoint`. That will give you the possibility to add other control plane down the road. In this example, the API endpoint is `k8sapi.isociel.com`. For a single control plane configuration, make sure you that it points to your single control plane. See the table below.

|Role|FQDN|IP|OS|Kernel|RAM|vCPU|
|----|----|----|----|----|----|----|
|Master|k8smaster1.isociel.com|192.168.13.61|Ubuntu 22.04.2|6.4.3|2G|2|
|Worker|k8sworker1.isociel.com|192.168.13.65|Ubuntu 22.04.2|6.4.3|2G|2|
|Worker|k8sworker2.isociel.com|192.168.13.66|Ubuntu 22.04.2|6.4.3|2G|2|
|Worker|k8sworker3.isociel.com|192.168.13.67|Ubuntu 22.04.2|6.4.3|2G|2|
|DNS Entry|k8sapi.isociel.com|192.168.13.61|N/A|N/A|N/A|N/A|

## Multiple Control Plane
If you plan to bootstrap multiple control plane, you will need a load balancer that will be the `controlPlaneEndpoint`. Your load balancer can be Nginx, HAProxy or whatever you like. In this example, the `controlPlaneEndpoint` is `k8sapi.isociel.com` and is your load balancer.

|Role|FQDN|IP|OS|Kernel|RAM|vCPU|
|----|----|----|----|----|----|----|
|Load Balancer|k8sapi.isociel.com|192.168.13.60|Ubuntu 22.04.2|6.4.3|2G|2|
|Master|k8smaster1.isociel.com|192.168.13.61|Ubuntu 22.04.2|6.4.3|2G|2|
|Master|k8smaster2.isociel.com|192.168.13.62|Ubuntu 22.04.2|6.4.3|2G|2|
|Master|k8smaster3.isociel.com|192.168.13.63|Ubuntu 22.04.2|6.4.3|2G|2|
|Worker|k8sworker1.isociel.com|192.168.13.65|Ubuntu 22.04.2|6.4.3|2G|2|
|Worker|k8sworker2.isociel.com|192.168.13.66|Ubuntu 22.04.2|6.4.3|2G|2|
|Worker|k8sworker3.isociel.com|192.168.13.67|Ubuntu 22.04.2|6.4.3|2G|2|

# Bootstrap `k8smaster1`
We start by bootstrapping the first control plane.

## Create configuration file
I decided to create a `yaml` file for `kubeadm` to bootstrap the K8s cluster. Since I'm planning to use either `Calico` or `Cilium` as my CNI, the cluster will be `kube-proxy` free 😉 This is the option `skipPhases: addon/kube-proxy`. If you need `kube-proxy`, just comment that line.

For the IP addresses assigned to **Pods** and **Services**, I will be using the following:
- Pods: `100.64.0.0/10`
  - Shared address space for communications between a service provider and its subscribers when using a carrier-grade NAT.
- Services: `198.18.0.0/16`
  - Used for benchmark testing of inter-network communications between two separate subnets.

>Note: Feel free to adjust the IP addresses above

### **You need to be connected to `k8smaster1`.**

Create a configuration file `kubeadm-k8smaster1-config.yaml` with the following content. Do not hesitate to modify it for your own environment:

```sh
cat <<EOF | tee kubeadm-k8smaster1-config.yaml
apiVersion: kubeadm.k8s.io/v1beta3
kind: InitConfiguration
nodeRegistration:
  criSocket: unix:///var/run/containerd/containerd.sock
localAPIEndpoint:
  advertiseAddress: 192.168.13.61
  bindPort: 6443
skipPhases:
  - addon/kube-proxy
---
apiVersion: kubeadm.k8s.io/v1beta3
kind: ClusterConfiguration
clusterName: k8s-cluster1
controlPlaneEndpoint: k8sapi.isociel.com:6443
networking:
  dnsDomain: cluster.local
  podSubnet: 100.64.0.0/10
  serviceSubnet: 198.18.0.0/16
apiServer:
  certSANs:
  - k8smaster1
  - k8smaster2
  - k8smaster3
  - k8sapi.isociel.com
  - k8smaster1.isociel.com
  - k8smaster2.isociel.com
  - k8smaster3.isociel.com
  - kubernetes
  - kubernetes.default
  - kubernetes.default.svc
  - kubernetes.default.svc.cluster.local
  - 192.168.13.60
  - 192.168.13.61
  - 192.168.13.62
  - 192.168.13.63
  timeoutForControlPlane: 4m0s
certificatesDir: /etc/kubernetes/pki
controllerManager:
  extraArgs:
    "node-cidr-mask-size": "24"
# ---
# Uncomment to use "IPVS" instead of "IPTABLES"
# apiVersion: kubeproxy.config.k8s.io/v1alpha1
# kind: KubeProxyConfiguration
# mode: ipvs
EOF
```

## Bootstrap the cluster
Run the following command to bootstrap `k8smaster1` and create the cluster:
```sh
sudo kubeadm init --config kubeadm-k8smaster1-config.yaml --upload-certs
```

Output:
```
[init] Using Kubernetes version: v1.27.3
[preflight] Running pre-flight checks
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
W0718 16:12:53.917797    1244 checks.go:835] detected that the sandbox image "registry.k8s.io/pause:3.6" of the container runtime is inconsistent with that used by kubeadm. It is recommended that using "registry.k8s.io/pause:3.9" as the CRI sandbox image.
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "ca" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8sapi.isociel.com k8smaster1 k8smaster1.isociel.com k8smaster2 k8smaster2.isociel.com k8smaster3 k8smaster3.isociel.com kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.192.0.1 192.168.13.61 192.168.13.60 192.168.13.62 192.168.13.63]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-ca" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/ca" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8smaster1.isociel.com localhost] and IPs [192.168.13.61 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8smaster1.isociel.com localhost] and IPs [192.168.13.61 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "sa" key and public key
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "kubelet.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Starting the kubelet
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[etcd] Creating static Pod manifest for local etcd in "/etc/kubernetes/manifests"
[wait-control-plane] Waiting for the kubelet to boot up the control plane as static Pods from directory "/etc/kubernetes/manifests". This can take up to 4m0s
[apiclient] All control plane components are healthy after 11.975579 seconds
[upload-config] Storing the configuration used in ConfigMap "kubeadm-config" in the "kube-system" Namespace
[kubelet] Creating a ConfigMap "kubelet-config" in namespace kube-system with the configuration for the kubelets in the cluster
[upload-certs] Storing the certificates in Secret "kubeadm-certs" in the "kube-system" Namespace
[upload-certs] Using certificate key:
4b94662202d60fafeef2b6bcdd26a1a565629182a63d2ed21ef5df27f4686ac1
[mark-control-plane] Marking the node k8smaster1.isociel.com as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node k8smaster1.isociel.com as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]
[bootstrap-token] Using token: x6gvlu.6deneaza4mow1qei
[bootstrap-token] Configuring bootstrap tokens, cluster-info ConfigMap, RBAC Roles
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to get nodes
[bootstrap-token] Configured RBAC rules to allow Node Bootstrap tokens to post CSRs in order for nodes to get long term certificate credentials
[bootstrap-token] Configured RBAC rules to allow the csrapprover controller automatically approve CSRs from a Node Bootstrap Token
[bootstrap-token] Configured RBAC rules to allow certificate rotation for all node client certificates in the cluster
[bootstrap-token] Creating the "cluster-info" ConfigMap in the "kube-public" namespace
[kubelet-finalize] Updating "/etc/kubernetes/kubelet.conf" to point to a rotatable kubelet client certificate and key
[addons] Applied essential addon: CoreDNS
[addons] Applied essential addon: kube-proxy

Your Kubernetes control-plane has initialized successfully!

To start using your cluster, you need to run the following as a regular user:

  mkdir -p $HOME/.kube
  sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
  sudo chown $(id -u):$(id -g) $HOME/.kube/config

Alternatively, if you are the root user, you can run:

  export KUBECONFIG=/etc/kubernetes/admin.conf

You should now deploy a pod network to the cluster.
Run "kubectl apply -f [podnetwork].yaml" with one of the options listed at:
  https://kubernetes.io/docs/concepts/cluster-administration/addons/

You can now join any number of the control-plane node running the following command on each as root:

  kubeadm join k8sapi.isociel.com:6443 --token x6gvlu.6deneaza4mow1qei \
	--discovery-token-ca-cert-hash sha256:c0d54017c9303d6bab8b1a1cbf6584d5d9ff8c9be5535cf562cca69c0f372502 \
	--control-plane --certificate-key 4b94662202d60fafeef2b6bcdd26a1a565629182a63d2ed21ef5df27f4686ac1

Please note that the certificate-key gives access to cluster sensitive data, keep it secret!
As a safeguard, uploaded-certs will be deleted in two hours; If necessary, you can use
"kubeadm init phase upload-certs --upload-certs" to reload certs afterward.

Then you can join any number of worker nodes by running the following on each as root:

kubeadm join k8sapi.isociel.com:6443 --token x6gvlu.6deneaza4mow1qei \
	--discovery-token-ca-cert-hash sha256:c0d54017c9303d6bab8b1a1cbf6584d5d9ff8c9be5535cf562cca69c0f372502 
```

## Start using the cluster
It's not mandatory to administor the cluster from a master node. I would say it's better to use a jump station but I deciced to copy the admin `kubeconfig` file in my local home directory on the master node anyway 😇:
```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

## Verification
Check that you have a cluster with one master node only with the command (Don't worry about the `NotReady`):
```sh
kubectl get nodes -o=wide
```

Output:
```
NAME                     STATUS     ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION         CONTAINER-RUNTIME
k8smaster1.isociel.com   NotReady   control-plane   50s   v1.27.4   192.168.13.61   <none>        Ubuntu 22.04.2 LTS   6.4.3-060403-generic   containerd://1.6.22
```

# Bootstrap another Control Plance
If you plan to bootstrap another Control Plane, follow the steps below for each one. If you don't plan to have a K8s Cluster in H.A., skip to the next section.

### **You need to be connected to `k8smaster2`.**
Now lets bootstarp `k8smaster2` within 2 hours of bootstraping `k8smaster1` since the *certificate-key* is ony valid for 2 hours. We use the command from the output of the `kubeadm init` we did in the preceeding step.

```sh
sudo kubeadm join k8sapi.isociel.com:6443 --token x6gvlu.6deneaza4mow1qei \
--discovery-token-ca-cert-hash sha256:c0d54017c9303d6bab8b1a1cbf6584d5d9ff8c9be5535cf562cca69c0f372502 \
--control-plane --certificate-key 4b94662202d60fafeef2b6bcdd26a1a565629182a63d2ed21ef5df27f4686ac1
```

Output:
```
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[preflight] Running pre-flight checks before initializing the new control plane instance
[preflight] Pulling images required for setting up a Kubernetes cluster
[preflight] This might take a minute or two, depending on the speed of your internet connection
[preflight] You can also perform this action in beforehand using 'kubeadm config images pull'
[download-certs] Downloading the certificates in Secret "kubeadm-certs" in the "kube-system" Namespace
[download-certs] Saving the certificates to the folder: "/etc/kubernetes/pki"
[certs] Using certificateDir folder "/etc/kubernetes/pki"
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8sapi.isociel.com k8smaster1 k8smaster1.isociel.com k8smaster2 k8smaster2.isociel.com k8smaster3 k8smaster3.isociel.com kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.192.0.1 192.168.13.62 192.168.13.60 192.168.13.61 192.168.13.63]
[certs] Generating "apiserver-kubelet-client" certificate and key
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8smaster2.isociel.com localhost] and IPs [192.168.13.62 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8smaster2.isociel.com localhost] and IPs [192.168.13.62 127.0.0.1 ::1]
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Valid certificates and keys now exist in "/etc/kubernetes/pki"
[certs] Using the existing "sa" key
[kubeconfig] Generating kubeconfig files
[kubeconfig] Using kubeconfig folder "/etc/kubernetes"
[kubeconfig] Writing "admin.conf" kubeconfig file
[kubeconfig] Writing "controller-manager.conf" kubeconfig file
[kubeconfig] Writing "scheduler.conf" kubeconfig file
[control-plane] Using manifest folder "/etc/kubernetes/manifests"
[control-plane] Creating static Pod manifest for "kube-apiserver"
[control-plane] Creating static Pod manifest for "kube-controller-manager"
[control-plane] Creating static Pod manifest for "kube-scheduler"
[check-etcd] Checking that the etcd cluster is healthy
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...
[etcd] Announced new etcd member joining to the existing etcd cluster
[etcd] Creating static Pod manifest for "etcd"
[etcd] Waiting for the new etcd member to join the cluster. This can take up to 40s
The 'update-status' phase is deprecated and will be removed in a future release. Currently it performs no operation
[mark-control-plane] Marking the node k8smaster2.isociel.com as control-plane by adding the labels: [node-role.kubernetes.io/control-plane node.kubernetes.io/exclude-from-external-load-balancers]
[mark-control-plane] Marking the node k8smaster2.isociel.com as control-plane by adding the taints [node-role.kubernetes.io/control-plane:NoSchedule]

This node has joined the cluster and a new control plane instance was created:

* Certificate signing request was sent to apiserver and approval was received.
* The Kubelet was informed of the new secure connection details.
* Control plane label and taint were applied to the new node.
* The Kubernetes control plane instances scaled up.
* A new etcd member was added to the local/stacked etcd cluster.

To start administering your cluster from this node, you need to run the following as a regular user:

	mkdir -p $HOME/.kube
	sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
	sudo chown $(id -u):$(id -g) $HOME/.kube/config

Run 'kubectl get nodes' to see this node join the cluster.
```

---------------------------
# Bootstrap Worker Node(s)
For every worker node you want to join, follow the steps below within 24 hours, since token will expire. Don't worry, you can generate anoter token.

### **You need to be connected to the worker node.**
You can join any number of `worker` nodes by running the following command, **on each**, as root:
```sh
sudo kubeadm join k8sapi.isociel.com:6443 --token x6gvlu.6deneaza4mow1qei \
	--discovery-token-ca-cert-hash sha256:c0d54017c9303d6bab8b1a1cbf6584d5d9ff8c9be5535cf562cca69c0f372502
```

## Add node role
I like to have a `ROLES` with `worker`, so I add a node role for each worker node with the command:
```sh
kubectl label node k8sworker1.isociel.com node-role.kubernetes.io/worker=myworker
kubectl label node k8sworker2.isociel.com node-role.kubernetes.io/worker=myworker
kubectl label node k8sworker3.isociel.com node-role.kubernetes.io/worker=myworker
```

## Verification
Check that you have all your nodes in your cluster with the command:
```sh
kubectl get nodes -o=wide
```

Output will be different depending on what you have bootstrapped:
```
NAME                     STATUS     ROLES           AGE    VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION         CONTAINER-RUNTIME
k8smaster1.isociel.com   NotReady   control-plane   24m    v1.27.4   192.168.13.61   <none>        Ubuntu 22.04.2 LTS   6.4.3-060403-generic   containerd://1.6.22
```

>**Note**: The status of `NotReady` is normal since we don't have a CNI.

# Bootstrap Worker Node
### **You need to be connected to the worker node.**
Now let's bootstrap `k8smaster3` more than 2 hours after bootstraping `k8smaster1`. The `certificate-key` shouldn't be valid. The command from the output of the `kubeadm init` we did for `k8smaster1` is not valid anymore.

```sh
kubectl get pods -A
```

You can see that we don't have any `kube-proxy` Pods:
```
NAMESPACE     NAME                                             READY   STATUS    RESTARTS   AGE
kube-system   coredns-5d78c9869d-85kzm                         0/1     Pending   0          114s
kube-system   coredns-5d78c9869d-tmr4p                         0/1     Pending   0          114s
kube-system   etcd-k8smaster1.isociel.com                      1/1     Running   0          2m6s
kube-system   kube-apiserver-k8smaster1.isociel.com            1/1     Running   0          2m10s
kube-system   kube-controller-manager-k8smaster1.isociel.com   1/1     Running   0          2m6s
kube-system   kube-scheduler-k8smaster1.isociel.com            1/1     Running   0          2m6s
```

# Install CNI
The next step is to install a CNI for networking inside your Kubernetes Cluster. You just need one, don't install both 😉

## Install Calico
Follow theses steps to install Calico [here](Calico/00-Install-Calico.md)

## Install Cilium
Follow theses steps to install Calico [here](Cilium/01-0-Install-Cilium.md)

# References
[Demystifying High Availability in Kubernetes Using Kubeadm](https://medium.com/velotio-perspectives/demystifying-high-availability-in-kubernetes-using-kubeadm-3d83ed8c458b)  
