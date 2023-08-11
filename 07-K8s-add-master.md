# Add a master node to a Kubernetes Cluster
This tutorial shows how to add a **master** node to an **existing** Kubernetes Cluster.

## REVERT THE LOAD BALANCER TO LAYER 4 OR IT WON'T WORK

## Prerequisite
For a Linux server to act as either a master or worker node, it needs to have the basic tools. Follow this tutorial [here](04-K8s-master-worker.md) to have everything installed.

## Information from existing cluster
You need the following information to add a master node to an existing Kubernetes Cluster.
- token
- discovery-token-ca-cert-hash
- certificate-key

The information can be taken from another master node.

# Token and Discovery Token CA Cert hash
To get the *join token*, login to a **existing** Kubernetes Master node and get the joining token with the command below. Tokens are usually valid for 24-hours. Chances are that this command won't return anything.
```sh
kubeadm token list
```

If no join token is available, generate a new join token using `kubeadm` command:
```sh
export JOIN_COMMAND=$(kubeadm token create --print-join-command)
echo ${JOIN_COMMAND}
```

You should see an output similar to this. In our case we have three (3) root CA so the command returns three (3) `discovery-token-ca-cert-hash`:
```
kubeadm join k8sapi.isociel.com:6443 --token dmpzpb.iyznr5p85yr9j4oi --discovery-token-ca-cert-hash sha256:c0d54017c9303d6bab8b1a1cbf6584d5d9ff8c9be5535cf562cca69c0f372502
```

# Certificate Key
Below is the command to generate a certificate key. This value is only good for two hours:
Generate 
```sh
export CERT_KEY=$( { sudo kubeadm --kubeconfig $HOME/.kube/config init phase upload-certs --upload-certs 2>/dev/null || echo 0; } | tail -n 1 )
echo ${CERT_KEY}
```

## Get the join command
Enter this to get the full `kubeadm join` command:
```sh
echo "sudo ${JOIN_COMMAND} --control-plane --certificate-key ${CERT_KEY}"
unset JOIN_COMMAND
unset CERT_KEY
```

# Join the new master node (New Master Node)
You will join a new master node to the existing Kubernetes Cluster. Copy the command from the output above to the new master node you want to join.

Start by login to the **new** master node you want to join the cluster, example `k8smaster2` and paste the commmand you got from the output above.

The command will look like this one (don't paste this one, chances are your keys will be different 😉):
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
[certs] Generating "front-proxy-client" certificate and key
[certs] Generating "apiserver-etcd-client" certificate and key
[certs] Generating "etcd/server" certificate and key
[certs] etcd/server serving cert is signed for DNS names [k8smaster2.isociel.com localhost] and IPs [192.168.13.62 127.0.0.1 ::1]
[certs] Generating "etcd/peer" certificate and key
[certs] etcd/peer serving cert is signed for DNS names [k8smaster2.isociel.com localhost] and IPs [192.168.13.62 127.0.0.1 ::1]
[certs] Generating "etcd/healthcheck-client" certificate and key
[certs] Generating "apiserver" certificate and key
[certs] apiserver serving cert is signed for DNS names [k8sapi.isociel.com k8smaster1 k8smaster1.isociel.com k8smaster2 k8smaster2.isociel.com k8smaster3 k8smaster3.isociel.com kubernetes kubernetes.default kubernetes.default.svc kubernetes.default.svc.cluster.local] and IPs [10.192.0.1 192.168.13.62 192.168.13.60 192.168.13.61 192.168.13.63]
[certs] Generating "apiserver-kubelet-client" certificate and key
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

## Check New Master Node
On the new master node, `k8smaster2`, install the `kubeconfig` file:
```sh
mkdir -p $HOME/.kube
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

The following command can be enter on any Master Node that has successfully join the cluster.  

Verify that the new worker node has joined the party 🎉
```sh
kubectl get nodes -o=wide
```

Output:
```
NAME                     STATUS   ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION         CONTAINER-RUNTIME
k8smaster1.isociel.com   Ready    control-plane   3d18h   v1.27.3   192.168.13.61   <none>        Ubuntu 22.04.2 LTS   6.4.3-060403-generic   containerd://1.6.21
k8smaster2.isociel.com   Ready    control-plane   3d18h   v1.27.3   192.168.13.62   <none>        Ubuntu 22.04.2 LTS   6.4.3-060403-generic   containerd://1.6.21
```

>Node should be `Ready` if you installed a `CNI `.
