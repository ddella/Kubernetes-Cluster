# Remove Worker node from an HA Kubernetes cluster
This tutorial applies only to **Worker** nodes in a Kubernetes Cluser.

# **NEVER DO THAT ON A MASTER NODE. YOU WILL BREAK YOUR CLUSTER**

All the steps below can be done from any node that has access to Kubernetes API, except the node you want to remove.

## Get the list of Worker Node
Use this comand to get the list of Worker node in your Kubernetes Cluster:
```sh
kubectl get node --selector='!node-role.kubernetes.io/control-plane' -o=wide
```

## Get the `etcd` Pods
Use this comand to get the list of `etcd` Pods in your Kubernetes Cluster:
```sh
kubectl -n kube-system get pods -l component=etcd
```

## Drain Pods on the node
Drain the Pods on the node, ignore daemonsets and remove local data:
```sh
kubectl drain --ignore-daemonsets --delete-emptydir-data <node name>
```

## Reset the node (On the deleted Worker Node)
Before removing the node, reset the state installed by `kubeadm`:
```sh
sudo kubeadm reset -f
```

## De Register Node
Use the following command to deregister the node from the cluster:
```sh
kubectl delete node <node name>
```

## Reset IP Tables (On the deleted Worker Node)
The reset process does not reset or clean up iptables rules or IPVS tables. If you wish to reset iptables, you must do so manually:
```sh
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```

If you want to reset the IPVS tables, you must run the following command:
```sh
sudo ipvsadm -C
```

>You will most probably get the message: `ipvsadm: command not found`

# Cleanup Worker Node (On the deleted Worker Node)
On the Worker node that was removed from the cluster, remove any `~/.kube` directory
```sh
rm -rf ~/.kube
```
