# **DOES NOT WORK !!!**

# Calico
This tutorial in about how to install Calico CNI on a Kubernetes Cluster without `kube-proxy`. I'll show how to install the eBPF dataplane during the initial installation of Calico. 

# How to

To install in eBPF mode, we recommend using the Tigera Operator to install Calico so these instructions use the operator. Installing Calico normally consists of the following stages:

- You need a K8s Cluster without `kube-proxy`.
- Install the Tigera Operator
- Apply a set of Custom Resources to tell the operator what to install.
- Wait for the operator to provision all the associated resources and report back via its status resource.

To install directly in eBPF is very similar; this guide explains the differences:

- Create a cluster suitable to run Calico, without `kube-proxy`, with the added requirement that the nodes must use a recent enough kernel.
- Create a config map with the "real" address of the API server. This allows the operator to install Calico with a direct connection to the API server so - that it can take over from kube-proxy.
- Install the Tigera Operator.
- Download and tweak the installation Custom Resource to tell the operator to use eBPF mode.
- Apply a set of Custom Resources to tell the operator what to install.
- Wait for the operator to provision all the associated resources and report back via its status resource.

These steps are explained in more detail below.

# Single Control Plane
This is the cluster used to install Calico in eBPF mode. 

In this example, the API endpoint is `k8sapi.isociel.com`. For a single control plane configuration, make sure you that it points to your single control plane. See the table below.

|Role|FQDN|IP|OS|Kernel|RAM|vCPU|
|----|----|----|----|----|----|----|
|Master|k8smaster1.isociel.com|192.168.13.61|Ubuntu 22.04.2|6.4.12|2G|2|
|Worker|k8sworker1.isociel.com|192.168.13.65|Ubuntu 22.04.2|6.4.12|2G|2|
|Worker|k8sworker2.isociel.com|192.168.13.66|Ubuntu 22.04.2|6.4.12|2G|2|
|Worker|k8sworker3.isociel.com|192.168.13.67|Ubuntu 22.04.2|6.4.12|2G|2|
|DNS Entry|k8sapi.isociel.com|192.168.13.61|N/A|N/A|N/A|N/A|

This is the state of the cluster before installing Calico:
```
kubectl get nodes -o wide
NAME                     STATUS     ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION          CONTAINER-RUNTIME
k8smaster1.isociel.com   NotReady   control-plane   36h   v1.28.1   192.168.13.61   <none>        Ubuntu 22.04.3 LTS   6.4.12-060412-generic   containerd://1.7.5
k8sworker1.isociel.com   NotReady   worker          36h   v1.28.1   192.168.13.65   <none>        Ubuntu 22.04.3 LTS   6.4.12-060412-generic   containerd://1.7.5
k8sworker2.isociel.com   NotReady   worker          36h   v1.28.1   192.168.13.66   <none>        Ubuntu 22.04.3 LTS   6.4.12-060412-generic   containerd://1.7.5
k8sworker3.isociel.com   NotReady   worker          36h   v1.28.1   192.168.13.67   <none>        Ubuntu 22.04.3 LTS   6.4.12-060412-generic   containerd://1.7.5
```

```
kubectl get pods -A
NAMESPACE     NAME                                             READY   STATUS    RESTARTS         AGE
kube-system   coredns-5dd5756b68-mszxv                         0/1     Pending   0                36h
kube-system   coredns-5dd5756b68-t6974                         0/1     Pending   0                36h
kube-system   etcd-k8smaster1.isociel.com                      1/1     Running   11 (5m47s ago)   36h
kube-system   kube-apiserver-k8smaster1.isociel.com            1/1     Running   11 (5m47s ago)   36h
kube-system   kube-controller-manager-k8smaster1.isociel.com   1/1     Running   11 (5m47s ago)   36h
kube-system   kube-scheduler-k8smaster1.isociel.com            1/1     Running   11 (5m47s ago)   36h
```

# Step 1: Create a K8s Cluster
Follow this tutorial to bootstrapped a K8s Cluster without `kube-proxy` [here](../05-k8s-master-only.md).

# Step 2: Create a ConfigMap
In eBPF mode, Calico takes over from kube-proxy. This means that, like kube-proxy, it needs to be able to reach the API server directly rather than by using the API server's ClusterIP. To tell Calico how to reach the API server we create a ConfigMap with the API server's "real" address. In this guide we do that before installing the Tigera Operator. That means that the operator itself can also use the direct connection and hence it doesn't require kube-proxy to be running.

The tabs below explain how to find the "real" address of the API server for a range of distributions. Note: In all cases it's important that the address used is stable even if your API server is restarted or scaled up/down. If you have multiple API servers, with DNS or other load balancing in front it's important to use the address of the load balancer. This prevents Calico from being disconnected if the API servers IP changes.

Create the following config map in the tigera-operator namespace using the host and port determined above::
```sh
export API_SERVER_IP=k8sapi.isociel.com
export API_SERVER_PORT=6443

cat <<EOF > calico-ConfigMap.yaml
apiVersion: v1
kind: Namespace
metadata:
  name: tigera-operator
  labels:
    name: tigera-operator
---
kind: ConfigMap
apiVersion: v1
metadata:
  name: kubernetes-services-endpoint
  namespace: tigera-operator
data:
  KUBERNETES_SERVICE_HOST: "${API_SERVER_IP}"
  KUBERNETES_SERVICE_PORT: "${API_SERVER_PORT}"
EOF
```

```sh
kubectl create -f calico-ConfigMap.yaml
```

# Step 3: Install the Tigera Operator
Get the latest version number of `calico` and download Tigera Calico operator and custom resource definitions manifest:
```sh
VER=$(curl -s https://api.github.com/repos/projectcalico/calico/releases/latest | grep tag_name | cut -d '"' -f 4|sed 's/v//g')
echo $VER
curl -LO https://raw.githubusercontent.com/projectcalico/calico/v${VER}/manifests/tigera-operator.yaml
curl -LO https://raw.githubusercontent.com/projectcalico/calico/v${VER}/manifests/custom-resources.yaml
```

Install Tigera Calico operator:
```sh
kubectl create -f tigera-operator.yaml
```

# Step 4: Tweak and apply installation Custom Resources
When the main install guide tells you to apply the custom-resources.yaml, typically by running kubectl create with the URL of the file directly, you should instead download the file, so that you can edit it:

```sh
cat <<EOF > custom-resources.yaml
# This section includes base Calico installation configuration.
# For more information, see: https://projectcalico.docs.tigera.io/master/reference/installation/api#operator.tigera.io/v1.Installation
apiVersion: operator.tigera.io/v1
kind: Installation
metadata:
  name: default
spec:
  # Configures Calico networking.
   # Added calicoNetwork section with linuxDataplane field
  calicoNetwork:
    linuxDataplane: BPF
    # Note: The ipPools section cannot be modified post-install.
    ipPools:
    - blockSize: 24
      cidr: 100.64.0.0/10
      # encapsulation: VXLANCrossSubnet
      # natOutgoing: Enabled
      nodeSelector: all()
---
# This section configures the Calico API server.
# For more information, see: https://projectcalico.docs.tigera.io/master/reference/installation/api#operator.tigera.io/v1.APIServer
apiVersion: operator.tigera.io/v1
kind: APIServer
metadata:
  name: default
spec: {}
EOF
```

Then apply the edited file:
```sh
kubectl create -f custom-resources.yaml
```

Restart the operator:
```sh
kubectl delete pod -n tigera-operator -l k8s-app=tigera-operator
```

# Reference
[Install in eBPF mode](https://docs.tigera.io/calico/latest/operations/ebpf/install)  
