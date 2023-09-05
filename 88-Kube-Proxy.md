# Install Kube-Proxy
After upgrade Kubernetest from v1.27.4 to v1.28.1 my whole cluster was down. I was running Cilium v1.14.0 `kube-proxy` free on Ubuntu with Kernel 6.4.12.

The only way to get my cluster back was to re-install `kube-proxy` with the following command:
```sh
sudo kubeadm init phase addon kube-proxy  --kubeconfig ~/.kube/config  --control-plane-endpoint k8sapi.isociel.com 
```

You can find the FQDN of the `--control-plane-endpoint` with the command:
```sh
kubectl config view -o go-template='{{range .clusters}}{{index .cluster "server"}}{{"\n"}}{{end}}'
```

This installs the `kube-proxy` addon components via the API server.

> **Note**
>I ran the command from a jump station.

# References
[Install the kube-proxy addon to a Kubernetes cluster](https://kubernetes.io/docs/reference/setup-tools/kubeadm/generated/kubeadm_init_phase_addon_kube-proxy/)  


# Kubernetes in IPVS mode (Optional)
If you alreay have a K8s Cluster using `kube-proxy` with `iptables` mode, you can switch to `ipvs` mode by following the steps below.

## Install IPVS
You need to have `ipvs` installed on **every** K8s nodes in your cluster. Follow the steps [here](./88-IPVS.md) to install the package.

## Edit running cluster
Use the following command to edit the configuration:
```sh
kubectl edit configmap kube-proxy -n kube-system
```

Change the `kube-proxy` mode from `mode: ""` to `mode: ipvs`:
```yaml
...
    kind: KubeProxyConfiguration
...
    mode: "ipvs"
...
```

## Reload `kube-proxy` Pods
Delete all `kube-proxy` Pods so they take the new modification:
```sh
kubectl delete pods -n kube-system -l k8s-app=kube-proxy
```

## Test IPVS mode
Verify that all your nodes are using `ipvs`. Check the logs of `kube-proxy` Pods for line with `"Using ipvs Proxier"`.

Get the name of all your `kube-proxy` Pods:
```sh
KUB_PROXY=$(kubectl get pods -n kube-system -l k8s-app=kube-proxy --no-headers -o custom-columns=":metadata.name")
```

Verify that your K8s Cluster runs in `ipvs` mode. You should have one line of output per node, either master or worker, in your cluster:
```sh
KUB_PROXY_ARR=($(echo $KUB_PROXY | tr " " "\n"))
for i in "${KUB_PROXY_ARR[@]}"; do kubectl logs "${i}" -n kube-system | grep "Using ipvs Proxier"; done
unset KUB_PROXY_ARR
unset KUB_PROXY
```

Output for a four-node K8s Cluster using `ipvs`:
```
I0904 00:36:28.919993       1 server_others.go:218] "Using ipvs Proxier"
I0904 00:36:28.937684       1 server_others.go:218] "Using ipvs Proxier"
I0904 00:36:28.781134       1 server_others.go:218] "Using ipvs Proxier"
I0904 00:36:29.225663       1 server_others.go:218] "Using ipvs Proxier"
```
