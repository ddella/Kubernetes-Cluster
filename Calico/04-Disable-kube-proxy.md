# kube-proxy
If you use your own CNI, it usually can replace `kube-proxy`. It's a waste of resources and reduces performance to run both. In this tutorial, I'll explain how to disable `kube-proxy`.

In this tutorial I assume you have a K8s cluster that runs `kube-proxy` with a DaemonSet (such as kubeadm).

# Check kube-proxy Pods
Verify that `kube-proxy` has a running Pod in every node in your cluster with the command:
```sh
kubectl get pod -n kube-system -l k8s-app=kube-proxy
```

Output should look like this:
```
NAME               READY   STATUS    RESTARTS   AGE
kube-proxy-h4lwc   1/1     Running   0          41s
kube-proxy-hn9fp   1/1     Running   0          41s
kube-proxy-l5v9w   1/1     Running   0          41s
kube-proxy-sxdnc   1/1     Running   0          41s
```

## NodeSelector
Check the node selector on `kube-proxy` before doing any changes, with the command:
```sh
kubectl describe ds -n kube-system kube-proxy | grep Node-Selector:
```

The only node selector on `kube-proxy` should be the following:
```
Node-Selector:  kubernetes.io/os=linux
```

# Disable kube-proxy
For a cluster that runs `kube-proxy` in a DaemonSet (such as a kubeadm-created cluster), you can disable `kube-proxy` reversibly by adding a dummy node selector to `kube-proxy`'s DaemonSet that matches no nodes, for example:
```sh
kubectl patch ds -n kube-system kube-proxy -p '{"spec":{"template":{"spec":{"nodeSelector":{"no-proxy": "true"}}}}}'
```

Output:
```
daemonset.apps/kube-proxy patched
```

`kube-proxy` is disabled 🎉 🥳

>I used `no-proxy`, which doesn't exist, as the node selector.

Check that there's nore more `kube-proxy` Pods in your cluster with the command:
```sh
kubectl get pod -n kube-system -l k8s-app=kube-proxy
```

Output should look like this:
```
No resources found in kube-system namespace.
```

Check that the node selector has been applied with the command:
```sh
kubectl describe ds -n kube-system kube-proxy | grep Node-Selector:
```

Output when a node selector has been added:
```
Node-Selector:  kubernetes.io/os=linux,no-proxy=true
```

At this point, we can look at the `kube-proxy` status of the cluster and see that DESIRED and CURRENT are both 0:
```sh
kubectl get ds -n kube-system kube-proxy
```

```
NAME         DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                          AGE
kube-proxy   0         0         0       0            0           kubernetes.io/os=linux,no-proxy=true   64d
```

# Enable kube-proxy
Should you want to start `kube-proxy` again, you can simply remove the node selector added above:
```sh
kubectl patch ds -n kube-system kube-proxy --type merge -p '{"spec":{"template":{"spec":{"nodeSelector":{"no-proxy": null}}}}}'
```

Verify that `kube-proxy` has a running Pod in every K8s node with the command:
```sh
kubectl get pod -n kube-system -l k8s-app=kube-proxy
```

Output should look like this:
```
NAME               READY   STATUS    RESTARTS   AGE
kube-proxy-ng8rc   1/1     Running   0          3s
kube-proxy-pb59j   1/1     Running   0          3s
kube-proxy-w9ntr   1/1     Running   0          4s
kube-proxy-zjcmj   1/1     Running   0          3s
```

Check that the node selector has been removed with the command:
```sh
kubectl describe ds -n kube-system kube-proxy | grep Node-Selector:
```

Output when no node selector has been added:
```
Node-Selector:  kubernetes.io/os=linux
```

# References
[Calico Docs](https://docs.tigera.io/calico/latest/operations/ebpf/enabling-ebpf)  
