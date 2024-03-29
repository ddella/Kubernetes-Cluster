# Upgrade Kubernetes Cluster Using Kubeadm
In this example, I will be upgrading Kubernetes version `1.28.1` to `1.28.2`.

We need to run the upgrades in the following order:

1. Control plane node(s)
2. Worker Nodes

Also, we need to upgrade the following components on the control plane(s), the worker nodes and every `bastion` hosts you use to manage your K8s cluster.

- Kubeadm
- Kubelet (not needed on bastion host)
- Kubectl

# Before
Before we get started, you should get the cluster node names with the following command:
```sh
kubectl get nodes -o wide
```

# Upgrade The Control Plane (Master Node)
Following are the high level steps to upgrade the control plane(s):

1. Check the existing version
2. Determine which version to upgrade to
3. unhold kubeadm and Install required kubeadm version
4. Upgrading first control plane node OR
5. Upgrading other control plane node(s)
6. Drain the node except daemonsets
7. Upgrade `kubectl` and `kubelet`
8. Uncordon the control plane
9. Verify the status of the cluster

Lets get started with the Upgrade.

# Step 1: Check the existing Kubeadm version
> [!IMPORTANT]  
> You **NEED** to be on a control plane. If you have more than one control plane, just pick one 😉

Login to the control plane and check the existing version using the following command.
```sh
kubeadm version -o yaml
```

# Step 2: Determine which version to upgrade to
You can get the list of available Kubeadm versions using the following command:
```sh
sudo apt update
sudo apt-cache madison kubeadm | head -5
```

Also you can run a `kubeadm upgrade plan` to get upgrade suggestions.
```sh
sudo kubeadm upgrade plan --ignore-preflight-errors 'all'
```

My current version is 1.28.1 and I will be upgrading to version 1.28.2.

# Step 3: unhold kubeadm and Install the required version
During the `kubeadm` installation, I have hold `kubeadm`, `kubectl` and `kubelet` to prevent unplanned upgrades.

We need to unhold `kubeadm`, install `v1.28.2-00` and hold it again, using the following command.
```sh
sudo apt-mark unhold kubeadm
sudo apt install -y kubeadm=1.28.2-00
sudo apt-mark hold kubeadm
```

# Step 4: Upgrading first control plane node
> [!IMPORTANT]  
> You do either **Step 4:** or **Step 5:** but not both. 
> The **Step 4:** is for the first control plane and **Step 5:** is for all other control plane.

The upgrade procedure on control plane nodes should be executed one node at a time. Pick a control plane node that you wish to upgrade first. It must have the `/etc/kubernetes/admin.conf` file.
```sh
sudo kubeadm upgrade apply v1.28.2
```

> [!NOTE]  
> I usually get this kind of error the first time I issue the command.
> `[ERROR ImagePull]: failed to pull image registry.k8s.io/kube-apiserver:v1.28.x`. I just do it again.

# Step 5: Upgrading other control plane node(s)
You do this step only if you have already upgraded one control plane node using the command in **Step 4**.
```sh
sudo kubeadm upgrade node
```

# Step 6: Drain the node except daemonsets
Prepare the node for maintenance by marking it unschedulable and evicting the workloads:
```sh
kubectl drain <node-to-drain> --ignore-daemonsets
```
> **Note**
>replace `<node-to-drain>` with the name of the node you are draining

# Step 7: Upgrade `kubectl` and `kubelet`
Upgrade `kubelet` and `kubectl`:
```sh
sudo apt-mark unhold kubelet kubectl
sudo apt update && sudo apt install -y kubelet=1.28.2-00 kubectl=1.28.2-00
sudo apt-mark hold kubelet kubectl
```

Restart `kubelet`:
```sh
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

# Step 8: Uncordon the control plane
Bring the node back online by marking it schedulable:
```sh
kubectl uncordon <node-to-uncordon>
```

> **Note**
>replace `<node-to-uncordon>` with the name of your node you are draining

# Step 9: Verify the status of the cluster
After the `kubelet` is upgraded on all control plane nodes verify that all nodes are available again by running the following command from anywhere `kubectl` can access the cluster:

```sh
kubectl get nodes -o wide
```

> **Note**
>The STATUS column should show Ready for all your nodes, and the version number should be updated.

# References
[Upgrading kubeadm clusters](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-upgrade/)  
[How to Upgrade Kubernetes Cluster Using Kubeadm?](https://devopscube.com/upgrade-kubernetes-cluster-kubeadm/)  

---

# Upgrade worker nodes
The upgrade procedure on worker nodes should be executed one node at a time or few nodes at a time, without compromising the minimum required capacity for running your workloads.

> [!IMPORTANT]  
>You need to upgrade the control plane nodes before upgrading your Linux Worker nodes.

# Step 1: Unhold `kubeadm` and install the required version
During the `kubeadm` installation, I have hold `kubeadm` to prevent upgrades.

We need to unhold `kubeadm`, install v1.28.0-00 and hold it again, using the following commands.
```sh
sudo apt-mark unhold kubeadm
sudo apt update && sudo apt install -y kubeadm=1.28.2-00
sudo apt-mark hold kubeadm
```

# Step 2: Upgrading worker node
For worker nodes this upgrades the local `kubelet`:
```sh
sudo kubeadm upgrade node
```

# Step 3: Drain the node except daemonsets
Prepare the node for maintenance by marking it unschedulable and evicting the workloads:
```sh
kubectl drain <node-to-drain> --ignore-daemonsets
```
> **Note**
>replace `<node-to-drain>` with the name of your node you are draining

# Step 4: Upgrade `kubectl` and `kubelet`
Upgrade `kubelet` and `kubectl`:
```sh
sudo apt-mark unhold kubelet kubectl
sudo apt update && sudo apt install -y kubelet=1.28.2-00 kubectl=1.28.2-00
sudo apt-mark hold kubelet kubectl
```

Restart `kubelet`:
```sh
sudo systemctl daemon-reload
sudo systemctl restart kubelet
```

# Step 5: Uncordon the control plane
Bring the node back online by marking it schedulable:
```sh
kubectl uncordon <node-to-uncordon>
```

> **Note**
>replace `<node-to-uncordon>` with the name of your node you are draining

# Step 6: Verify the status of the cluster
After `kubelet` is upgraded, verify that the node is available again by running the following command from anywhere `kubectl` can access the cluster:

```sh
kubectl get nodes
```

Output after the upgrade:
```
NAME                     STATUS   ROLES           AGE   VERSION
k8smaster1.isociel.com   Ready    control-plane   26d   v1.28.2
k8sworker1.isociel.com   Ready    worker          26d   v1.28.2
k8sworker2.isociel.com   Ready    worker          26d   v1.28.2
k8sworker3.isociel.com   Ready    worker          26d   v1.28.2
```

> **Note**
>The STATUS column should show Ready for all your nodes, and the version number should be updated.

# References
[Upgrading Linux nodes](https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/upgrading-linux-nodes/)  

Congradulation, your cluster should run the latest version of Kubernetes 🎉🎉🎉

---

# Upgrade your bastion host(s)
If you manage your cluster from a `bastion host`, don't forget to update `kubectl` on it.

Upgrade `kubectl`:
```sh
sudo apt-mark unhold kubectl
sudo apt update && sudo apt install -y kubectl=1.28.2-00
sudo apt-mark hold kubectl
```

After `kubelet` is upgraded, verify the version and that you have access to the cluster:
```sh
kubectl version -o yaml
kubectl get nodes -o wide
```

---

# How it works

`kubeadm upgrade apply` does the following on your first control plane:

    Checks that your cluster is in an upgradeable state:
        The API server is reachable
        All nodes are in the Ready state
        The control plane is healthy
    Enforces the version skew policies.
    Makes sure the control plane images are available or available to pull to the machine.
    Generates replacements and/or uses user supplied overwrites if component configs require version upgrades.
    Upgrades the control plane components or rollbacks if any of them fails to come up.
    Applies the new CoreDNS and kube-proxy manifests and makes sure that all necessary RBAC rules are created.
    Creates new certificate and key files of the API server and backs up old files if they're about to expire in 180 days.

`kubeadm upgrade node` does the following on additional control plane nodes if you have an H.A cluster:

    Fetches the kubeadm ClusterConfiguration from the cluster.
    Optionally backups the kube-apiserver certificate.
    Upgrades the static Pod manifests for the control plane components.
    Upgrades the kubelet configuration for this node.

`kubeadm upgrade node` does the following on worker nodes:

    Fetches the kubeadm ClusterConfiguration from the cluster.
    Upgrades the kubelet configuration for this node.
