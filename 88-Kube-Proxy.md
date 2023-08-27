# Install Kube-Proxy
After upgrade Kubernetest from v1.27.4 to v1.28.1 my whole cluster was down. I was running Cilium v1.14.0 `kube-proxy` free on Ubuntu with Kernel 6.4.12.

The only way to get my cluster back was to re-install `kube-proxy` with the following command:
```sh
sudo kubeadm init phase addon kube-proxy  --kubeconfig ~/.kube/config  --control-plane-endpoint k8sapi.isociel.com 
```

This installs the `kube-proxy` addon components via the API server.

> **Note**
>I ran the command from a jump station.

# References
[Install the kube-proxy addon to a Kubernetes cluster](https://kubernetes.io/docs/reference/setup-tools/kubeadm/generated/kubeadm_init_phase_addon_kube-proxy/)  
