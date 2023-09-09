# Kubernetes Cheat Sheet
```sh
# Get the Pods CIDR allocated on each node
kubectl describe node | grep PodCIDR: -A 1
kubectl get nodes -o yaml

# kubectl explain is a kind of built-in documentation for YAML k8s manifest files.
kubectl explain pods

# Can be used to get the logs of a deployment or pods with appropriate parameters to log the same
kubectl logs deployment/webapp --since 5m > /tmp/logs.txt

# To see which Kubernetes resources are and aren't in a namespace:
# In a namespace
kubectl api-resources --namespaced=true

# Not in a namespace
kubectl api-resources --namespaced=false

# Use this command to check the status of all the cluster components:
kubectl get --raw='/readyz?verbose'

# Check certificate expiration (https://kubernetes.io/docs/tasks/administer-cluster/kubeadm/kubeadm-certs/)
kubeadm certs check-expiration

# Get the client certificate inside the `kubeconfig` file:
cat ~/.kube/config | grep client-certificate-data | cut -f2 -d : | tr -d ' ' | base64 -d | openssl x509 -text -noout -
kubectl config view --raw -o jsonpath='{range .users[*].user}{.client-certificate-data}' | base64 -d | openssl x509 -text -noout -
kubectl config view --raw -o go-template='{{range .users}}{{index .user "client-certificate-data"}}{{"\n"}}{{end}}' | base64 -d | openssl x509 -text -noout -

# Get the client private key inside the `kubeconfig` file:
cat ~/.kube/config | grep client-key-data | cut -f2 -d : | tr -d ' ' | base64 -d
kubectl config view --raw -o jsonpath='{range .users[*].user}{.client-key-data}' | base64 -d
kubectl config view --raw -o go-template='{{range .users}}{{index .user "client-key-data"}}{{"\n"}}{{end}}' | base64 -d | openssl pkey -inform pem -text -noout -

# Get the CA certificate
kubectl config view --raw -o go-template='{{range .clusters}}{{index .cluster "certificate-authority-data"}}{{"\n"}}{{end}}' | base64 -d

# Get the API Server URL
kubectl config view -o go-template='{{range .clusters}}{{.cluster.server}}{{"\n"}}{{end}}'

# Get Deployment
kubectl get deploy -n kube-system

# Get Node Label (remove node name for ALL)
kubectl get nodes k8sworker1.isociel.com --show-labels

# Get CoreDNS configuration
kubectl get configmap -n kube-system coredns -o yaml

# Get Pods version and registry
kubectl get pods --all-namespaces -o jsonpath="{.items[*].spec.containers[*].image}" | tr -s '[[:space:]]' '\n' | uniq -c | sort -r

# Get the cluster name
kubectl cluster-info dump | grep "\-\-cluster-name" | tr -d '[:blank:] , "'
```

# Cilium Cheat Sheet
```sh
cilium status -o json
# Get the current agent configuration
cilium config view

# IP Pool
kubectl get ippools

# Validate that the CiliumPodIPPool resource
kubectl get ciliumpodippool -A -o yaml

#
kubectl -n kube-system exec ds/cilium -- cilium service list

# 
kubectl exec -it -n kube-system cilium-XXXXX -- cilium status --verbose

# Export the current ConfigMap
kubectl get configmap -n kube-system cilium-config -o yaml --export > cilium-cm-backup.yaml

# Generate the ConfigMap
helm template cilium/cilium --namespace kube-system \
--set bpf.masquerade=true \
--set bpf.hostRouting=true \
--set bgpControlPlane.enabled=true \
--set kubeProxyReplacement=true \
--set k8sServiceHost=${API_SERVER_IP} \
--set k8sServicePort=${API_SERVER_PORT} \
--set prometheus.enabled=true \
--set operator.prometheus.enabled=true \
--set ipam.mode=cluster-pool \
--set ipam.operator.clusterPoolIPv4PodCIDRList=["100.64.0.0/10"] \
--set ipam.operator.clusterPoolIPv4MaskSize=26 \
--set hubble.enabled=true \
--set hubble.relay.enabled=true \
--set hubble.ui.enabled=true \
--set hubble.metrics.enableOpenMetrics=true \
--set hubble.metrics.enabled="{dns,drop,tcp,flow,port-distribution,icmp,httpV2:exemplars=true;labelsContext=source_ip\,source_namespace\,source_workload\,destination_ip\,destination_namespace\,destination_workload\,traffic_direction}" \
  > cilium-configmap.yaml

# Apply new ConfigMap
kubectl apply -n kube-system -f cilium-cm-new.yaml

# View all helm values
helm show values cilium/cilium > heml.yaml

# Ger Cilium Nodes
kubectl get ciliumnodes.cilium.io

# Troubleshoot
curl -sLO https://raw.githubusercontent.com/cilium/cilium/main/contrib/k8s/k8s-cilium-exec.sh
chmod +x ./k8s-cilium-exec.sh
./k8s-cilium-exec.sh cilium status

# Get the deployment in a namespace
k get deploy -n nginx-ns -o yaml

# Edit the deployment
k edit deploy nginx-test -n nginx-ns

# Find the logs of nginx-test containers
kubectl -n nginx-ns logs deploy/nginx-test -c nginx-test
```

# References - Kubernetes
[kubectl Cheat Sheet](https://kubernetes.io/docs/reference/kubectl/cheatsheet/)  

# References (clean me please 😀)
https://raesene.github.io/blog/2023/03/18/lets-talk-about-anonymous-access-to-Kubernetes/
https://kubernetes.io/docs/setup/best-practices/certificates/
https://kubernetes.io/docs/reference/access-authn-authz/kubelet-tls-bootstrapping/
https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/#kubeadm-k8s-io-v1beta3-ClusterConfiguration
https://pkg.go.dev/k8s.io/kubernetes/cmd/kubeadm/app/apis/kubeadm/v1beta3
https://kubernetes.io/docs/reference/config-api/kubeadm-config.v1beta3/
https://kubernetes.io/docs/setup/production-environment/tools/kubeadm/high-availability/

# References - Cilium
[Cheat Sheet](https://docs.cilium.io/en/stable/cheatsheet/)  
[Load Balancer](https://docs.cilium.io/en/latest/network/lb-ipam/)  

