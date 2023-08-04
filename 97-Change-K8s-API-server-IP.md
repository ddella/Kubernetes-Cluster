# How to Change Kubernetes API server IP Address
### DISCLAIMER: THIS IS UNSUPPORTED BY KUBERNETES. NEVER DO THAT FOR A PRODUCTION CLUSTER!!!

### DOES **NOT** WORK!!!

### If you need to change the IP address of the Control Plane, just create a new cluster an migrate all your Pods. This procedure is for educational purposes **ONLY**. You will need to reset all your worker nodes, so expect a downtime with this procedure.

This tutorial applies to a standalone Kubernetes Cluster that was bootstrapped with `kubeadm`. This will demonstrate how to change the IP address of the control plane.

# Remove ALL worker node
You need to remove all worker node from the cluster. Follow [those steps](99-Remove-Worker-Node.md) to remove a worker node. Repeat for every node.

# Change the IP
Change the IP address on the control plane. On Ubuntu, edit the file:
```sh
sudo vi /etc/netplan/00-installer-config.yaml
```

# Backup K8s data on Control Plane
Run the following command on your K8s Control Plane:
```sh
# Keep a backup of your kube-config file
cp ~/.kube/config ~/.kube/config.bak

# Stop Service
sudo systemctl stop kubelet containerd

# Backup Kubernetes and kubelet
sudo apt install -y rsync
mkdir ~/k8s-backup/
sudo rsync -avru --mkpath --progress /etc/kubernetes/ ~/k8s-backup/etc/kubernetes/
sudo rsync -avru --mkpath --progress /var/lib/kubelet ~/k8s-backup/var/lib/kubelet/

# You should find your old IP address in all the following files
sudo grep --include=\*.{conf,yaml} -Rnw '/etc/kubernetes/' -e "192.168.13.30"

#Change ip's in the following files
sudo sed -i -e 's/192.168.13.30/k8smaster1.isociel.com/g' /etc/kubernetes/admin.conf
sudo sed -i -e 's/192.168.13.30/k8smaster1.isociel.com/g' /etc/kubernetes/controller-manager.conf
sudo sed -i -e 's/192.168.13.30/k8smaster1.isociel.com/g' /etc/kubernetes/kubelet.conf
sudo sed -i -e 's/192.168.13.30/k8smaster1.isociel.com/g' /etc/kubernetes/scheduler.conf

# Don't ask me why but for etcd you need the IP addr. not the DNS name
sudo sed -i -e 's/192.168.13.30/192.168.13.61/g' /etc/kubernetes/manifests/etcd.yaml

sudo sed -i -e 's/192.168.13.30/k8smaster1.isociel.com/g' /etc/kubernetes/manifests/kube-apiserver.yaml
# Let the IP in file: /etc/kubernetes/manifests/kube-apiserver.yaml
#   - --advertise-address=192.168.13.61
sudo sed -i -e 's/advertise-address=k8smaster1.isociel.com/advertise-address=192.168.13.61/g' /etc/kubernetes/manifests/kube-apiserver.yaml

# Delete existing certificates that have the old IP addr
sudo rm -f /etc/kubernetes/pki/{apiserver.*,etcd/peer.*,etcd/server.*,apiserver-kubelet-client.*}

# Create new certificates
sudo kubeadm init phase certs apiserver-kubelet-client
sudo kubeadm init phase certs apiserver
sudo kubeadm init phase certs etcd-peer
sudo kubeadm init phase certs etcd-server

# Restart services and check status
sudo systemctl restart kubelet containerd
sudo systemctl status containerd
sudo systemctl status kubelet

# Move current config file under user for current user's access
sudo cp -i /etc/kubernetes/admin.conf $HOME/.kube/config
sudo chown $(id -u):$(id -g) $HOME/.kube/config
```

# Reset every Worker node (On EVERY worker node)
```sh
sudo kubeadm reset -f
rm -f $HOME/.kube/config
```

# Get Token
On the control plane, generate a new join token using `kubeadm` command:
```sh
export K_JOIN=$(kubeadm token create --print-join-command) > /dev/null
echo "sudo ${K_JOIN}"
```

Copy the output and paste it in a worker node. The command should look like this:
```
sudo kubeadm join k8smaster1.isociel.com:6443 --token ouocdy.r5whpxjofxaqwqpp --discovery-token-ca-cert-hash sha256:b2ba89dffd6a9b804ce1af22f0158b9169b8a22788db847cb142c8bf49ae72c4
```
# Verify result
Check all the Pods. In my case, some Pods from my CNI were not running:
```sh
kubectl get pods -A
```

# References

# Troubleshoot
This listing shows our running containers. One of them should be `kube-apiserver`. If everything goes well, it should vanish for a few seconds and reappear:

```sh
crictl ps
```

```
CONTAINER           IMAGE               CREATED             STATE               NAME                      ATTEMPT             POD ID              POD
76c72bab216bd       89e70da428d29       15 minutes ago      Running             kube-scheduler            20                  ad1effd91001f       kube-scheduler-k8smaster1.isociel.com
1a2dd268f847e       ac2b7465ebba9       15 minutes ago      Running             kube-controller-manager   21                  d16046dfc7559       kube-controller-manager-k8smaster1.isociel.com
```

