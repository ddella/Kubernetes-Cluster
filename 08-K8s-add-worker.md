# Add a worker node to a Kubernetes Cluster
This tutorial shows how to add a **worker** node to an **existing** Kubernetes Cluster.

## REVERT THE LOAD BALANCER TO LAYER 4 OR IT WON'T WORK

## Prerequisite
For a Linux server to act as either a master or worker node, it needs to have the basic tools. Follow this tutorial [here](04-K8s-master-worker.md) to have everything installed.

## Information from existing cluster
You need the following information to add a master node to an existing Kubernetes Cluster.
- token
- discovery-token-ca-cert-hash

The information can be taken from any master node.

# Token and Discovery Token CA Cert hash
To get the *join token*, login to a **existing** Kubernetes Master node and get the joining token with the command below. Tokens are usually valid for 24-hours. Chances are that this command won't return anything. If it does return something and you really want to use it, you'll need the digest of the root CA. See the step `Token list not empty **ONLY**` at the bottom to get it. I recommand creating a new token.
```sh
kubeadm token list
```

If no join token is available, generate a new join token using `kubeadm` command:
```sh
kubeadm token create --print-join-command
```

You should see an output similar to this:
```
kubeadm join k8sapi.isociel.com:6443 --token dmpzpb.iyznr5p85yr9j4oi --discovery-token-ca-cert-hash sha256:c0d54017c9303d6bab8b1a1cbf6584d5d9ff8c9be5535cf562cca69c0f372502
```

# Join the new worker node (New Worker Node)
You will join a new worker node to the existing Kubernetes Cluster. Copy the command from the output above to the new worker node you want to join.

Start by login to the **new** worker node you want to join the cluster, example `k8sworker1` and paste the commmand you got from the output above.

The command will look like this one (don't paste this one, chances are your keys will be different 😉):
```sh
sudo kubeadm join k8sapi.isociel.com:6443 --token kp7f2v.610kb5smc87njj3x \
--discovery-token-ca-cert-hash sha256:c0d54017c9303d6bab8b1a1cbf6584d5d9ff8c9be5535cf562cca69c0f372502
```

Output:
```
[preflight] Running pre-flight checks
[preflight] Reading configuration from the cluster...
[preflight] FYI: You can look at this config file with 'kubectl -n kube-system get cm kubeadm-config -o yaml'
[kubelet-start] Writing kubelet configuration to file "/var/lib/kubelet/config.yaml"
[kubelet-start] Writing kubelet environment file with flags to file "/var/lib/kubelet/kubeadm-flags.env"
[kubelet-start] Starting the kubelet
[kubelet-start] Waiting for the kubelet to perform the TLS Bootstrap...

This node has joined the cluster:
* Certificate signing request was sent to apiserver and a response was received.
* The Kubelet was informed of the new secure connection details.

Run 'kubectl get nodes' on the control-plane to see this node join the cluster.
```

## Add node role
I like to have a `ROLES` with `worker`, so I added a node role:
```sh
kubectl label node k8sworker1.isociel.com node-role.kubernetes.io/worker=myworker
```

## Check New Worker Node
On any master node, verify that the new worker node has joined the party 🎉
```sh
kubectl get nodes -o=wide
```

Output:
```
NAME                     STATUS   ROLES           AGE     VERSION   INTERNAL-IP     EXTERNAL-IP   OS-IMAGE             KERNEL-VERSION         CONTAINER-RUNTIME
k8smaster1.isociel.com   Ready    control-plane   3d18h   v1.27.3   192.168.13.61   <none>        Ubuntu 22.04.2 LTS   6.4.3-060403-generic   containerd://1.6.21
k8smaster2.isociel.com   Ready    control-plane   3d18h   v1.27.3   192.168.13.62   <none>        Ubuntu 22.04.2 LTS   6.4.3-060403-generic   containerd://1.6.21
k8smaster3.isociel.com   Ready    control-plane   23m     v1.27.4   192.168.13.63   <none>        Ubuntu 22.04.2 LTS   6.4.3-060403-generic   containerd://1.6.21
k8sworker1.isociel.com   Ready    worker          3m5s    v1.27.4   192.168.13.65   <none>        Ubuntu 22.04.2 LTS   6.4.3-060403-generic   containerd://1.6.21
```

>Node should be `Ready` if you installed a `CNI `.

# Token list not empty **ONLY** (DON't DO THE NEXT STEPS)
The easiest way to join a worker node it to generate a token list. If you want to reuse an existing token, you'll need the `sha256` of the control plane CA. A token exists is the command `kubeadm token list` returns something.

To get the full join command, log to the control plane and execute this script:
```sh
# IP address of the control plane
ipaddr = "192.168.13.161"
# SHA of CA certificate
sha_token = "$(openssl x509 -pubkey -in /etc/kubernetes/pki/ca.crt | openssl rsa -pubin -outform der 2>/dev/null | openssl dgst -sha256 -hex | sed 's/^.* //')"
# Token to join the cluster
token = "$(kubeadm token list | awk '{print $1}' | sed -n '2 p')"
# The whole join command
echo "sudo kubeadm join $ipaddr:6443 --token=$token --discovery-token-ca-cert-hash sha256:$sha_token"
```

>**Note**:Change the 'ipaddr' for the load balancer, if you have a Kubernetes Cluster in H.A. or the IP address/DNS of the control plane. 😉
