# Upgrading an installation that uses the operator
This page describes how to upgrade Calico from Calico v3.x or later. The procedure varies by datastore type and install method. In this case, we're using `Tigera Operator`.

The upgrade can be done from any jump station that is already configured to access your Kubernetes Cluster. It doesn't need to be done on the Control Plane.

This assumes you already have Calico working in your K8s cluster with a version 3.x and want to upgrade to a version 3.y, where `y > x`.

## Check version
In my case, I already upgraded the utility `calicoctl` to v3.26.1 and the cluster is running v3.26.0. See below the output of the command:
```sh
calicoctl version
```

```
Client Version:    v3.26.1
Git commit:        b1d192c95
Cluster Version:   v3.26.0
Cluster Type:      typha,kdd,k8s,operator,bgp,kubeadm
```

## Get the latest version number of `calico`
```sh
VER=$(curl -s https://api.github.com/repos/projectcalico/calico/releases/latest | grep tag_name | cut -d '"' -f 4|sed 's/v//g')
echo $VER
```

>**Wait**: Make sure your actual version can be upgraded to the latest version.

## Download Tigera Calico operator manifest file
```sh
curl -LO https://raw.githubusercontent.com/projectcalico/calico/v${VER}/manifests/tigera-operator.yaml
```

## Upgrade
Use the following command to initiate an upgrade:
```sh
kubectl replace -f tigera-operator.yaml
```

Output:
```
namespace/tigera-operator replaced
customresourcedefinition.apiextensions.k8s.io/bgpconfigurations.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/bgpfilters.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/bgppeers.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/blockaffinities.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/caliconodestatuses.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/clusterinformations.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/felixconfigurations.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/globalnetworkpolicies.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/globalnetworksets.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/hostendpoints.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/ipamblocks.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/ipamconfigs.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/ipamhandles.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/ippools.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/ipreservations.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/kubecontrollersconfigurations.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/networkpolicies.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/networksets.crd.projectcalico.org replaced
customresourcedefinition.apiextensions.k8s.io/apiservers.operator.tigera.io replaced
customresourcedefinition.apiextensions.k8s.io/imagesets.operator.tigera.io replaced
customresourcedefinition.apiextensions.k8s.io/installations.operator.tigera.io replaced
customresourcedefinition.apiextensions.k8s.io/tigerastatuses.operator.tigera.io replaced
serviceaccount/tigera-operator replaced
clusterrole.rbac.authorization.k8s.io/tigera-operator replaced
clusterrolebinding.rbac.authorization.k8s.io/tigera-operator replaced
deployment.apps/tigera-operator replaced
```

## Check the upgrade
You can check the upgrade in real time with the command:
```sh
watch -n 1 "kubectl get po -n calico-apiserver && kubectl get po -n calico-system"
```

You will see the Pods going into different state like `ContainerCreating` and `Init:0/2`. When the upgrade is completed, all the Pods should be in status `Running`.


# Upgrade `calicoctl` utility
Don't forget to upgrade `calicoctl` binary on all the hosts where it's installed.

Use the following command to download the `calicoctl` binary file and install it:
```sh
curl -L https://github.com/projectcalico/calico/releases/latest/download/calicoctl-linux-amd64 -o calicoctl
chmod +x ./calicoctl
sudo mv calicoctl /usr/local/bin
sudo chown root:adm /usr/local/bin/calicoctl
```

>**Note**: I installed `calicoctl` on the master node and any jump station only.

# Upgrade Verification
Verify that the upgrade has been successfully completed with the command:
```sh
calicoctl version
```

Output:
```
Client Version:    v3.26.1
Git commit:        b1d192c95
Cluster Version:   v3.26.1
Cluster Type:      typha,kdd,k8s,operator,bgp,kubeadm
```

In my case I upgraded Calico from 3.26.0 to 3.26.1.

# Calico Images (On Master Node)
You can see that Calico downloaded the new images and let the old one in the local registry. When your satisfied with the upgrade, you can delete the old images. The command in this section needs to be executed on the Control Plane. You can use either `crictl` or `nerdctl`. The later one will give you a near Docker experience.

## `crictl`
This is `containerd` own CLI, however, it's only for testing purpose and it is used to test low-level functionality of `containerd`. The design of `crictl` is not very user friendly and it lacks of many docker CLI features. You should use `nerdctl`, see next section.

I specified the `runtime-endpoint`. Some installation still have Docker installed and in my case I'm using `containerd`. I just wanted to be sure that I query the correct local registry:
```sh
crictl --runtime-endpoint unix:///run/containerd/containerd.sock images ls
```

Output:
```
IMAGE                                     TAG                 IMAGE ID            SIZE
docker.io/calico/cni                      v3.26.0             5d6f5c26c6554       93.3MB
docker.io/calico/cni                      v3.26.1             9dee260ef7f59       93.4MB
docker.io/calico/csi                      v3.26.0             151c86d530ac9       9.87MB
docker.io/calico/csi                      v3.26.1             677ad13d73108       8.91MB
docker.io/calico/node-driver-registrar    v3.26.0             f26b4a3a9c76f       12.2MB
docker.io/calico/node-driver-registrar    v3.26.1             c623084712495       11MB
docker.io/calico/node                     v3.26.0             44f52c09decec       87.6MB
docker.io/calico/node                     v3.26.1             8065b798a4d67       86.6MB
docker.io/calico/pod2daemon-flexvol       v3.26.0             d9eeedbe7ebbf       7.28MB
docker.io/calico/pod2daemon-flexvol       v3.26.1             092a973bb20ee       7.29MB
docker.io/calico/typha                    v3.26.1             66bcdacc0ea35       28.3MB
quay.io/prometheus/node-exporter          v1.5.0              0da6a335fe135       11.5MB
registry.k8s.io/coredns/coredns           v1.10.1             ead0a4a53df89       16.2MB
registry.k8s.io/etcd                      3.5.7-0             86b6af7dd652c       102MB
registry.k8s.io/kube-apiserver            v1.27.2             c5b13e4f7806d       33.4MB
registry.k8s.io/kube-controller-manager   v1.27.2             ac2b7465ebba9       31MB
registry.k8s.io/kube-proxy                v1.27.2             b8aa50768fd67       23.9MB
registry.k8s.io/kube-scheduler            v1.27.2             89e70da428d29       18.2MB
registry.k8s.io/pause                     3.6                 6270bb605e12e       302kB
registry.k8s.io/pause                     3.9                 e6f1816883972       322kB
```

## `nerdctl`
```sh
sudo nerdctl --namespace k8s.io image ls
```

Show untagged images (dangling):
```sh
sudo nerdctl --namespace k8s.io image ls --filter "dangling=true"
```

Show images with a TAG of `v3.26.0`. In our case here, that's the old Calico version:
```sh
sudo nerdctl --namespace k8s.io image ls --filter "reference=v3.26.0"
```

Let's remove the Calico images from version v3.26.0 to free up space in our local registry with the command below:
```sh
sudo nerdctl --namespace k8s.io image rm -f $(sudo nerdctl --namespace k8s.io image ls --filter "reference=v3.26.0" -q)
```

>**Note**: This above command needs to be run locally on every Master and Worker node in your cluster.

# Reference
[Upgrade Calico](https://docs.tigera.io/calico/latest/operations/upgrading/kubernetes-upgrade#upgrading-an-installation-that-uses-the-operator)
[nerdctl command reference](https://github.com/containerd/nerdctl/blob/main/docs/command-reference.md)  
