# TroubleShooting
https://docs.cilium.io/en/stable/operations/troubleshooting/

# Validate the Setup
After deploying Cilium, we can first validate that the Cilium agent is running in the desired mode:

```sh
kubectl -n kube-system exec ds/cilium -- cilium status --verbose
kubectl -n kube-system exec ds/cilium -- cilium status | grep Masquerading
```

# References
[Kubernetes Without kube-proxy](https://docs.cilium.io/en/stable/network/kubernetes/kubeproxy-free/)  
[Helm Reference](https://docs.cilium.io/en/stable/helm-reference/)  
[use Cilium to fully replace kube-proxy](https://www.yfdou.com/archives/use-Cilium-to-fully-replace-kube-proxy.html)  
