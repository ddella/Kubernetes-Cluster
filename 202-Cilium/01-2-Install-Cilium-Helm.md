# Cilium Installation using Helm
This guide will show you how to install Cilium using Helm. This involves a couple of additional steps compared to the Cilium Quick Installation and requires you to manually select the best datapath and IPAM mode for your particular environment.

You should already have a Kubernetes Cluster, either single Control Plane or multiple Control Plane (H.A.).

# Install Helm
This tutorial shows how to install the Helm CLI. Helm can be installed either from source, or from pre-built binary releases. I'm using `pre-built binary`.

Follow this guide to install Helm from pre-built binary [here](../helm.md)
```sh
helm version --template='Version: {{.Version}}{{"\n"}}'
```

Output:
```
Version: v3.12.2
```

# Setup Helm repository
```sh
helm repo add cilium https://helm.cilium.io/
```

Output:
```
"cilium" has been added to your repositories
```

# Check available version
You can check the available version with Cilium CLI:
```sh
cilium install --list-versions | head -n 5
```

# Install Cilium
Requirements:

- Kubernetes must be configured to use CNI (see Network Plugin Requirements)
- Linux kernel >= 4.9.17

To deploy Cilium via Helm, just type the command:
```sh
export API_SERVER_IP=k8sapi.isociel.com
export API_SERVER_PORT=6443

cat <<EOF > values.yaml
# tunnel: disabled
# ipv4NativeRoutingCIDR: "100.64.0.0/10"
kubeProxyReplacement: true
ipam:
  mode: kubernetes
  # operator:
  #   clusterPoolIPv4PodCIDRList: ["100.64.0.0/10"]
  #   clusterPoolIPv4MaskSize: 24
bgpControlPlane:
  enabled: true
bpf:
  masquerade: true
  hostRouting: true 
k8sServiceHost: ${API_SERVER_IP}
k8sServicePort: ${API_SERVER_PORT}
prometheus:
  enabled: true
hubble:
  enabled: true
  metrics:
    enableOpenMetrics: true
  relay:
    enabled: true
EOF
```

```
?????????????????????????????
--set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}"

# --set bgp.enabled=true \
# --set bgpControlPlane.enabled=true \
# --set ipam.mode=kubernetes \
# --set ipv4NativeRoutingCIDR=10.224.0.0/16 \
# --set loadBalancer.algorithm=maglev \
# --set loadBalancer.mode=dsr \
# --set tunnel=disabled
```

Install Cilium with the command:
```sh
helm install -n kube-system cilium cilium/cilium --version v1.14.0 -f values.yaml
```

Output form the install command:
```
NAME: cilium
LAST DEPLOYED: Wed Aug  2 09:44:20 2023
NAMESPACE: kube-system
STATUS: deployed
REVISION: 1
TEST SUITE: None
NOTES:
You have successfully installed Cilium with Hubble Relay and Hubble UI.

Your release version is 1.14.0.

For any further help, visit https://docs.cilium.io/en/v1.14/gettinghelp
```
# Validate the Installation
### To validate that Cilium has been properly installed, you can run the following command:
```sh
cilium status --wait
```

```
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    disabled (using embedded mode)
 \__/¯¯\__/    Hubble Relay:       OK
    \__/       ClusterMesh:        disabled

Deployment             cilium-operator    Desired: 2, Ready: 2/2, Available: 2/2
Deployment             hubble-relay       Desired: 1, Ready: 1/1, Available: 1/1
DaemonSet              cilium             Desired: 4, Ready: 4/4, Available: 4/4
Deployment             hubble-ui          Desired: 1, Ready: 1/1, Available: 1/1
Containers:            hubble-relay       Running: 1
                       hubble-ui          Running: 1
                       cilium             Running: 4
                       cilium-operator    Running: 2
Cluster Pods:          7/7 managed by Cilium
Helm chart version:    1.14.0
Image versions         cilium             quay.io/cilium/cilium:v1.14.0@sha256:5a94b561f4651fcfd85970a50bc78b201cfbd6e2ab1a03848eab25a82832653a: 4
                       cilium-operator    quay.io/cilium/operator-generic:v1.14.0@sha256:3014d4bcb8352f0ddef90fa3b5eb1bbf179b91024813a90a0066eb4517ba93c9: 2
                       hubble-relay       quay.io/cilium/hubble-relay:v1.14.0@sha256:bfe6ef86a1c0f1c3e8b105735aa31db64bcea97dd4732db6d0448c55a3c8e70c: 1
                       hubble-ui          quay.io/cilium/hubble-ui:v0.12.0@sha256:1c876cfa1d5e35bc91e1025c9314f922041592a88b03313c22c1f97a5d2ba88f: 1
                       hubble-ui          quay.io/cilium/hubble-ui-backend:v0.12.0@sha256:8a79a1aad4fc9c2aa2b3e4379af0af872a89fcec9d99e117188190671c66fc2e: 1
```

### Check the K8s nodes:
```sh
kubectl get nodes -o wide
```

You're looking for a status of `Ready` on all the nodes:
```
NAME                     STATUS   ROLES           AGE   VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION         CONTAINER-RUNTIME
k8smaster1.isociel.com   Ready    control-plane   16m   v1.27.4   192.168.13.61   <none>        Ubuntu 22.04.3 LTS   6.4.3-060403-generic   containerd://1.6.22
k8sworker1.isociel.com   Ready    worker          15m   v1.27.4   192.168.13.65   <none>        Ubuntu 22.04.3 LTS   6.4.3-060403-generic   containerd://1.6.22
k8sworker2.isociel.com   Ready    worker          15m   v1.27.4   192.168.13.66   <none>        Ubuntu 22.04.3 LTS   6.4.3-060403-generic   containerd://1.6.22
k8sworker3.isociel.com   Ready    worker          15m   v1.27.4   192.168.13.67   <none>        Ubuntu 22.04.3 LTS   6.4.3-060403-generic   containerd://1.6.22
```

### Check the Pods state:
```sh
kubectl get pods -A
```

All the Pods should `Running`:
```
NAMESPACE     NAME                                             READY   STATUS    RESTARTS   AGE
kube-system   cilium-b89jb                                     1/1     Running   0          68s
kube-system   cilium-hzq4w                                     1/1     Running   0          68s
kube-system   cilium-operator-5b48f66d85-4892j                 1/1     Running   0          68s
kube-system   cilium-operator-5b48f66d85-pdkhp                 1/1     Running   0          68s
kube-system   cilium-pbhjc                                     1/1     Running   0          68s
kube-system   cilium-sbmrg                                     1/1     Running   0          68s
kube-system   coredns-5d78c9869d-85kzm                         1/1     Running   0          15m
kube-system   coredns-5d78c9869d-tmr4p                         1/1     Running   0          15m
kube-system   etcd-k8smaster1.isociel.com                      1/1     Running   0          16m
kube-system   hubble-relay-79d64897bd-dbbqm                    1/1     Running   0          68s
kube-system   kube-apiserver-k8smaster1.isociel.com            1/1     Running   0          16m
kube-system   kube-controller-manager-k8smaster1.isociel.com   1/1     Running   0          16m
kube-system   kube-scheduler-k8smaster1.isociel.com            1/1     Running   0          16m
```

#### Congratulations! You have a fully functional Kubernetes cluster with Cilium. 🥳 🎉

# Restart unmanaged Pods (**Not needed for fresh install**)
If you did not create a cluster with the nodes tainted with the taint `node.cilium.io/agent-not-ready`, then unmanaged pods need to be restarted manually. Restart all already running pods which are not running in host-networking mode to ensure that Cilium starts managing them. This is required to ensure that all pods which have been running before Cilium was deployed have network connectivity provided by Cilium and NetworkPolicy applies to them:

```sh
kubectl get pods --all-namespaces -o custom-columns=NAMESPACE:.metadata.namespace,NAME:.metadata.name,HOSTNETWORK:.spec.hostNetwork --no-headers=true | grep '<none>' | awk '{print "-n "$1" "$2}' | xargs -L 1 -r kubectl delete pod
```

# Cilium network connectivity
Start port forwarding for Hubble so Cilium can test it:
```sh
cilium hubble port-forward&
CILIUM_PID=$!
```

Output (don't worry, we've catched the PID and will kill the port forwarding process when we're done 😉):
```
[1] 10270
```

If you don't enable port forwarding, the Hubble test will be skipped and you'll see the following warning:
```
🔭 Enabling Hubble telescope...
⚠️  Unable to contact Hubble Relay, disabling Hubble telescope and flow validation: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial tcp 127.0.0.1:4245: connect: connection refused"
ℹ️  Expose Relay locally with:
   cilium hubble enable
   cilium hubble port-forward&
```

Run the following command to validate that your cluster has proper network connectivity:
```sh
cilium connectivity test
```

>Be patient!

Output of the last line:
```
........

✅ All 42 tests (306 actions) successful, 13 tests skipped, 0 scenarios skipped.
```

Terminate the port forwarding we started earlier:
```sh
kill -SIGTERM -- -${CILIUM_PID}
unset CILIUM_PID
```

# Cleanup
After running Cilium connectivity test, it left behind lots of ressources in namespace `cilium-test`.
```sh
kubectl get all -n cilium-test
```

Output:
```
NAME                                      READY   STATUS    RESTARTS   AGE
pod/client-6b4b857d98-jqhd9               1/1     Running   0          23m
pod/client2-646b88fb9b-zhpv7              1/1     Running   0          23m
pod/echo-external-node-545d98c9b4-kcbzf   0/1     Pending   0          23m
pod/echo-other-node-545c9b778b-d9m8s      2/2     Running   0          23m
pod/echo-same-node-965bbc7d4-hkkzd        2/2     Running   0          23m
pod/host-netns-28gvg                      1/1     Running   0          23m
pod/host-netns-86n25                      1/1     Running   0          23m
pod/host-netns-vflkb                      1/1     Running   0          23m

NAME                      TYPE       CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
service/echo-other-node   NodePort   10.192.192.2     <none>        8080:31308/TCP   23m
service/echo-same-node    NodePort   10.192.222.121   <none>        8080:30818/TCP   23m

NAME                                   DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR                AGE
daemonset.apps/host-netns              3         3         3       3            3           <none>                       23m
daemonset.apps/host-netns-non-cilium   0         0         0       0            0           cilium.io/no-schedule=true   23m

NAME                                 READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/client               1/1     1            1           23m
deployment.apps/client2              1/1     1            1           23m
deployment.apps/echo-external-node   0/1     1            0           23m
deployment.apps/echo-other-node      1/1     1            1           23m
deployment.apps/echo-same-node       1/1     1            1           23m

NAME                                            DESIRED   CURRENT   READY   AGE
replicaset.apps/client-6b4b857d98               1         1         1       23m
replicaset.apps/client2-646b88fb9b              1         1         1       23m
replicaset.apps/echo-external-node-545d98c9b4   1         1         0       23m
replicaset.apps/echo-other-node-545c9b778b      1         1         1       23m
replicaset.apps/echo-same-node-965bbc7d4        1         1         1       23m
```

### Cleanup Cilium test
You can delete the namespace, this will delete everything that belongs to it:
```sh
kubectl delete namespace cilium-test
```

Output:
```
namespace "cilium-test" deleted
```

>Looks like delete is not being done on purpose right now to allow re-running tests quickly.

# Uninstall Cilium
In case you want to uninstall Cilium, use the following command:
```sh
helm uninstall -n kube-system cilium
```

Output:
```
🔥 Deleting pods in cilium-test namespace...
🔥 Deleting cilium-test namespace...
```

# References
[Introduction to Cilium & Hubble](https://docs.cilium.io/en/stable/overview/intro/)  
[Cilium Quick Installation](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)  
[Installing Helm](https://helm.sh/docs/intro/install/)  
[Tutorial: Tips and Tricks to install Cilium](https://isovalent.com/blog/post/tutorial-tips-and-tricks-to-install-cilium/)  
[Helm Reference](https://docs.cilium.io/en/stable/helm-reference/)  
[Helm Key/Value](https://artifacthub.io/packages/helm/cilium/cilium)  

# Check Cilium state

### All Pods should be in STATUS `Running`:
```sh
kubectl get pod -n kube-system -o wide
```

```
NAME                                             READY   STATUS    RESTARTS   AGE   IP              NODE                     NOMINATED NODE   READINESS GATES
cilium-b89jb                                     1/1     Running   0          11m   192.168.13.67   k8sworker3.isociel.com   <none>           <none>
cilium-hzq4w                                     1/1     Running   0          11m   192.168.13.65   k8sworker1.isociel.com   <none>           <none>
cilium-operator-5b48f66d85-4892j                 1/1     Running   0          11m   192.168.13.66   k8sworker2.isociel.com   <none>           <none>
cilium-operator-5b48f66d85-pdkhp                 1/1     Running   0          11m   192.168.13.65   k8sworker1.isociel.com   <none>           <none>
cilium-pbhjc                                     1/1     Running   0          11m   192.168.13.61   k8smaster1.isociel.com   <none>           <none>
cilium-sbmrg                                     1/1     Running   0          11m   192.168.13.66   k8sworker2.isociel.com   <none>           <none>
coredns-5d78c9869d-85kzm                         1/1     Running   0          25m   100.64.3.218    k8sworker3.isociel.com   <none>           <none>
coredns-5d78c9869d-tmr4p                         1/1     Running   0          25m   100.64.3.2      k8sworker3.isociel.com   <none>           <none>
etcd-k8smaster1.isociel.com                      1/1     Running   0          26m   192.168.13.61   k8smaster1.isociel.com   <none>           <none>
hubble-relay-79d64897bd-dbbqm                    1/1     Running   0          11m   100.64.3.185    k8sworker3.isociel.com   <none>           <none>
kube-apiserver-k8smaster1.isociel.com            1/1     Running   0          26m   192.168.13.61   k8smaster1.isociel.com   <none>           <none>
kube-controller-manager-k8smaster1.isociel.com   1/1     Running   0          26m   192.168.13.61   k8smaster1.isociel.com   <none>           <none>
kube-scheduler-k8smaster1.isociel.com            1/1     Running   0          26m   192.168.13.61   k8smaster1.isociel.com   <none>           <none>
```

### Cilium Status
Validate the Setup for each Cilium Pods by using the `--verbose` flags for full details:
```sh
for p in $(kubectl get pods --namespace=kube-system -l k8s-app=cilium -o name); do kubectl exec -it -n kube-system $p -- cilium status --verbose; done
```

>This is a lengthy output. You can execute the command for each Cilium Pod.

### Check the services
You can check the services for each Cilium Pod.

```sh
for p in $(kubectl get pods --namespace=kube-system -l k8s-app=cilium -o name); do kubectl exec -it -n kube-system $p -- cilium service list; done
```

>This is a lengthy output. You can execute the command for each Cilium Pod.

### DNS
Check CoreDNS logs:
```sh
for p in $(kubectl get pods --namespace=kube-system -l k8s-app=kube-dns -o name); do kubectl logs --namespace=kube-system $p; done
```

```sh
kubectl logs --namespace=kube-system coredns-5d78c9869d-5rbp7
```
