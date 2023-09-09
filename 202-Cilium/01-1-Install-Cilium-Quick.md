# Cilium Quick Installation
This guide will walk you through the quick default installation for Cilium CNI. It will automatically detect and use the best configuration possible for the Kubernetes distribution you are using. All state is stored using Kubernetes custom resource definitions (CRDs).

This is the best installation method for most use cases. For large environments (> 500 nodes) or if you want to run specific datapath modes, refer to the Getting Started guide.

You should already have a Kubernetes Cluster, either single Control Plane or H.A.

# Install the Cilium CLI
This will only work on a Linux base machine. Refere to Cilium [Cilium Quick Installation](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/) for other OS.

```sh
CILIUM_CLI_VERSION=$(curl -s https://raw.githubusercontent.com/cilium/cilium-cli/main/stable.txt)
CLI_ARCH=amd64
echo ${CILIUM_CLI_VERSION}

curl -L --fail --remote-name-all https://github.com/cilium/cilium-cli/releases/download/${CILIUM_CLI_VERSION}/cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
sha256sum --check cilium-linux-${CLI_ARCH}.tar.gz.sha256sum
sudo tar xzvfC cilium-linux-${CLI_ARCH}.tar.gz /usr/local/bin
sudo chown root:adm /usr/local/bin/cilium
rm cilium-linux-${CLI_ARCH}.tar.gz{,.sha256sum}
unset CILIUM_CLI_VERSION
unset CLI_ARCH
```

### Autocompletion (optional)
If you like, you can enable `cilium` autocompletion for `bash` with the following commands:
```sh
cilium completion bash | sudo tee /etc/bash_completion.d/cilium > /dev/null
source ~/.bashrc
```

## Verify
Check the version of Cilium CLI with the command:
```sh
cilium version --client
```

Output:
```
cilium-cli: v0.15.3 compiled with go1.20.4 on linux/amd64
cilium image (default): v1.13.4
cilium image (stable): v1.14.0
```

# Install Cilium
Requirements:

    Kubernetes must be configured to use CNI (see Network Plugin Requirements)
    Linux kernel >= 4.9.17

Install Cilium into the Kubernetes cluster pointed to by your current `kubectl` context. What it means is that you must have the file `$HOME/.kube/config` on your system for Cilium to reach your K8s Cluster:
```sh
cilium install
```
>The above command will install the latest stable release. If you need a specific version, use the flag `--version=x.y.z`

Output form the install command:
```
ℹ️  Using Cilium version 1.13.4
🔮 Auto-detected cluster name: k8s-cluster1
🔮 Auto-detected datapath mode: tunnel
🔮 Auto-detected kube-proxy has been installed
```

# Validate the Installation 
To validate that Cilium has been properly installed, you can run the following command:
```sh
cilium status --wait
```

Output:
```
    /¯¯\
 /¯¯\__/¯¯\    Cilium:             OK
 \__/¯¯\__/    Operator:           OK
 /¯¯\__/¯¯\    Envoy DaemonSet:    disabled (using embedded mode)
 \__/¯¯\__/    Hubble Relay:       disabled
    \__/       ClusterMesh:        disabled

DaemonSet              cilium             Desired: 4, Ready: 4/4, Available: 4/4
Deployment             cilium-operator    Desired: 1, Ready: 1/1, Available: 1/1
Containers:            cilium             Running: 4
                       cilium-operator    Running: 1
Cluster Pods:          2/2 managed by Cilium
Helm chart version:    1.13.4
Image versions         cilium             quay.io/cilium/cilium:v1.13.4@sha256:bde8800d61aaad8b8451b10e247ac7bdeb7af187bb698f83d40ad75a38c1ee6b: 4
                       cilium-operator    quay.io/cilium/operator-generic:v1.13.4@sha256:09ab77d324ef4d31f7d341f97ec5a2a4860910076046d57a2d61494d426c6301: 1
```

Congratulations! You have a fully functional Kubernetes cluster with Cilium. 🥳 🎉

# Cilium network connectivity
Run the following command to validate that your cluster has proper network connectivity:
```sh
cilium connectivity test
```

You will see this warning about Hubble, that's normal since we didn't install it:
```
🔭 Enabling Hubble telescope...
⚠️  Unable to contact Hubble Relay, disabling Hubble telescope and flow validation: rpc error: code = Unavailable desc = connection error: desc = "transport: Error while dialing: dial tcp 127.0.0.1:4245: connect: connection refused"
ℹ️  Expose Relay locally with:
   cilium hubble enable
   cilium hubble port-forward&
ℹ️  Cilium version: 1.13.4
```

The last line of the output should look like this:
```
✅ All 42 tests (302 actions) successful, 12 tests skipped, 1 scenarios skipped.
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

## Cleanup Cilium test
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
If you want to uninstall Cilium, use the following command:
```sh
cilium uninstall
```

Output:
```
🔥 Deleting pods in cilium-test namespace...
🔥 Deleting cilium-test namespace...
```

# References
[Introduction to Cilium & Hubble](https://docs.cilium.io/en/stable/overview/intro/)  
[Cilium Quick Installation](https://docs.cilium.io/en/stable/gettingstarted/k8s-install-default/)  
