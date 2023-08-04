# Upgrade Cilium (TO BE COMPLETED)
This upgrade guide is intended for Cilium running on Kubernetes.

Check the running version **before** the upgrade with the command:
```sh
cilium version
```

The output shoud look like this:
```
cilium-cli: v0.15.3 compiled with go1.20.4 on linux/amd64
cilium image (default): v1.13.4
cilium image (stable): v1.14.0
cilium image (running): 1.13.4
```

# Upgrade with CLI
To upgrade to a specific version of Cilium, use the command:
```sh
cilium upgrade --version v1.14.x
```

# Upgrade wih Helm
To upgrade using a local Helm chart:
```sh
helm upgrade cilium cilium/cilium --version 1.14.0 \
  --namespace=kube-system \
  --set upgradeCompatibility=1.X
```

# Rebasing a ConfigMap
This section describes the procedure to rebase an existing ConfigMap to the template of another version.

### Export the current ConfigMap
```sh
kubectl get configmap -n kube-system cilium-config -o yaml --export > cilium-cm-old.yaml
```

### Add new options
Add/Modify new options manually to your old ConfigMap `cilium-cm-old.yaml`.

### Apply new ConfigMap
After adding the options, manually save the file with your changes and install the ConfigMap in the kube-system namespace of your cluster.

```sh
kubectl apply -n kube-system -f ./cilium-cm-old.yaml
```

# Reference
[Upgrade Guide](https://docs.cilium.io/en/stable/operations/upgrade/)  
[GitHub](https://github.com/cilium/cilium-cli)  
