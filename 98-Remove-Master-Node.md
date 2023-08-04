# Remove Master node from an HA Kubernetes cluster
This tutorial applies only to **Master** nodes in a Kubernetes Cluser.

# **MAKE SURE YOU HAVE A BACKUP OF THE MASTER NODE. YOU CAN BREAK YOUR CLUSTER**

All the steps below can be done from any node that has access to Kubernetes API, except the node you want to remove.

## Get the list of Master Node
Use this comand to get the list of Worker node in your Kubernetes Cluster:
```sh
kubectl get node --selector='node-role.kubernetes.io/control-plane' -o=wide
```

## Get the `etcd` Pods
Use this comand to get the list of `etcd` Pods in your Kubernetes Cluster:
```sh
kubectl -n kube-system get pods -l component=etcd
```

## Drain Pods on the node
Drain the Pods on the Master node you want to remove, ignore daemonsets and remove local data:
```sh
kubectl drain --ignore-daemonsets --delete-local-data <node name>
```

## De Register Node
Use the following command to deregister the node from the cluster:
```sh
kubectl delete node <node name>
```

# Clean etcd
This is where it gets ugly and dangerous. If you don't remove your node from `etcd` you will **BREAK** your cluster.

## Jump inside `etcd` Pod
Get inside Master node `etcd` pod.
```sh
kubectl -n kube-system exec -ti etcd-k8smaster2.isociel.com -- sh
```

## Get ID
You need the `ID` of the `etcd` nodes for the delete command.

Use this command to get the `ID` of the master node you whish to delete:
```sh
etcdctl -w table member list --cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key
```

Output:
```
+------------------+---------+------------------------+----------------------------+----------------------------+------------+
|        ID        | STATUS  |          NAME          |         PEER ADDRS         |        CLIENT ADDRS        | IS LEARNER |
+------------------+---------+------------------------+----------------------------+----------------------------+------------+
| 126f93fb9e501e87 | started | k8smaster2.isociel.com | https://192.168.13.62:2380 | https://192.168.13.62:2379 |      false |
| aa290e410cc1091c | started | k8smaster1.isociel.com | https://192.168.13.61:2380 | https://192.168.13.61:2379 |      false |
+------------------+---------+------------------------+----------------------------+----------------------------+------------+
```

## Delete
Now we can remove the `k8smaster2.isociel.com` node using its ID.
```sh
etcdctl member remove 126f93fb9e501e87 --cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key
```

Use this command to list the master nodes, the one you deleted shouldn't appear anymore:
```sh
etcdctl -w table member list --cacert /etc/kubernetes/pki/etcd/ca.crt \
--cert /etc/kubernetes/pki/etcd/server.crt --key /etc/kubernetes/pki/etcd/server.key
```

# Cleanup the Master node (on the master you just removed)
The next two commands **must** 
## Reset the node
Before removing the node, reset the state installed by `kubeadm`:
```sh
sudo kubeadm reset -f
```

## Cleanup the Node
On the Worker node that was removed from the cluster, remove any `~/.kube` directory
```sh
rm -rf ~/.kube
```
## Reset IP Tables
The reset process does not reset or clean up iptables rules or IPVS tables. If you wish to reset iptables, you must do so manually:
```sh
sudo iptables -F && sudo iptables -t nat -F && sudo iptables -t mangle -F && sudo iptables -X
```

If you want to reset the IPVS tables, you must run the following command:
```sh
sudo ipvsadm -C
```
