# Load Balancer
LB IPAM is a feature that allows Cilium to assign IP addresses to Services of type LoadBalancer. This functionality is usually left up to a cloud provider, however, when deploying in a private cloud environment, these facilities are not always available.

LB IPAM works in conjunction with features like the Cilium BGP Control Plane (Beta). Where LB IPAM is responsible for allocation and assigning of IPs to Service objects and other features are responsible for load balancing and/or advertisement of these IPs.

LB IPAM is always enabled but dormant. The controller is awoken when the first IP Pool is added to the cluster.

# Nginx Deployment
This tutorial uses a simple Nginx web server deployment to demonstrate the concept of load balancer and external IP addresses.

### Create NameSpace
Create a namespace for this demo. It will be our selector to assign external load balancer IP addresses:
```sh
cat <<EOF > nginx-ns.yaml
kind: Namespace
apiVersion: v1
metadata:
  name: nginx
  labels:
    name: nginx
EOF
```

```sh
kubectl create -f nginx-ns.yaml
```

### Create Deployment
This will create three Pods in NameSpace `nginx`:
```sh
cat <<EOF > nginx-dp.yaml
apiVersion: apps/v1
kind: Deployment
metadata:
  name: my-nginx
  namespace: nginx
spec:
  selector:
    matchLabels:
      run: my-nginx
  replicas: 6
  template:
    metadata:
      labels:
        run: my-nginx
    spec:
      containers:
      - name: my-nginx
        image: nginx
        ports:
        - containerPort: 80
EOF
```

```sh
kubectl create -f nginx-dp.yaml
```

# Verify
Check that the Pods are running in the namespace `nginx`:
```sh
kubectl get pods -n nginx -l run=my-nginx -o wide
```

Output:
```
NAME                        READY   STATUS    RESTARTS   AGE     IP              NODE                     NOMINATED NODE   READINESS GATES
my-nginx-646554d7fd-q98dp   1/1     Running   0          7m36s   10.224.56.31    k8sworker3.isociel.com   <none>           <none>
my-nginx-646554d7fd-twbtl   1/1     Running   0          7m36s   10.224.21.140   k8sworker1.isociel.com   <none>           <none>
my-nginx-646554d7fd-w4jt4   1/1     Running   0          7m36s   10.224.36.155   k8sworker2.isociel.com   <none>           <none>
```

Another way to get the IP address of the Pods and on what node they are running:
```sh
kubectl get pods -l run=my-nginx -n nginx -o go-template='{{- range .items -}}K8s Node: {{.spec.nodeName}} --- Pod IP: {{.status.podIP}}{{"\n"}}{{- end -}}'
```

Output:
```
K8s Node: k8sworker3.isociel.com --- Pod IP: 10.224.56.31
K8s Node: k8sworker1.isociel.com --- Pod IP: 10.224.21.140
K8s Node: k8sworker2.isociel.com --- Pod IP: 10.224.36.155
```

# LB IPAM
LB IPAM has the notion of IP Pools which the administrator can create to tell Cilium which IP ranges can be used to allocate IPs from.

Below is a manifest to create two IP Pools:
- An IP Pools with both an IPv4 and IPv6 range named `blue-pool`
- An IP Pools with IPv4 only and a selector based on the NameSpace named `red-pool`

```sh
cat <<EOF > ippool.yaml
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "blue-pool"
spec:
  cidrs:
  - cidr: "198.18.0.0/16"
  - cidr: "2004::0/64"
  serviceSelector:
    matchExpressions:
      - {key: color, operator: In, values: [blue, cyan]}
---
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "red-pool"
spec:
  cidrs:
  - cidr: "198.19.0.0/16"
  serviceSelector:
    matchLabels:
      io.kubernetes.service.namespace: nginx
      # color: red
EOF
```

### Create the Pool
```sh
kubectl create -f ippool.yaml
```

```
ciliumloadbalancerippool.cilium.io/blue-pool created
ciliumloadbalancerippool.cilium.io/red-pool created
```

After adding the pool to the cluster, it appears like so:
```sh
kubectl get ippools
```

Output:
```
NAME        DISABLED   CONFLICTING   IPS AVAILABLE   AGE
blue-pool   false      False         131068          91s
red-pool    false      False         65533           91s
```

# Services
Any service with `.spec.type=LoadBalancer` can get IPs from any pool as long as the IP Pool’s service selector matches the service. If you omit the key/value `type: LoadBalancer` when you create the K8s service, Cilium won't allocate the External IP.

Create a simple service:
```sh
cat <<EOF > nginx-svc.yaml
apiVersion: v1
kind: Service
metadata:
  name: my-nginx
  namespace: nginx
  labels:
    run: my-nginx
    color: red
spec:
  type: LoadBalancer
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: my-nginx
EOF
```

### Create the Service
```sh
kubectl create -f nginx-svc.yaml
```

Output:
```
service/my-nginx created
```

### Service Info
Check the external IP of the service created above.
```sh
kubectl get svc -n nginx
```

Output:
```
NAME       TYPE           CLUSTER-IP       EXTERNAL-IP     PORT(S)        AGE
my-nginx   LoadBalancer   10.192.160.186   198.19.104.55   80:31325/TCP   90s
```

The EXTERNAL-IP has been taken from the `Red-Pool` with CIDR 198.19.0.0/16.

# Test
Let's test our Nginx deployment by pointing a client to the external IP of the load balancer. 

I'm on a server that is **not** part of the K8s cluster. Since the external IP is unkown, I need to add a static route or have some kind of routing protocol to advertise the external subnet.

### Add Static Route
I added a static route poiting to the master node in my K8s cluster with the command below:
```sh
sudo ip route add 198.19.0.0/16 via 192.168.13.61
```

>You don't need to add the static route to K8s nodes, either master or worker, since they know the External IP of the service.

Get the web page, with cURL, from a server not member of the K8s cluster:
```sh
curl http://198.19.104.55
```

Output:
```html
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
html { color-scheme: light dark; }
body { width: 35em; margin: 0 auto;
font-family: Tahoma, Verdana, Arial, sans-serif; }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>

<p>For online documentation and support please refer to
<a href="http://nginx.org/">nginx.org</a>.<br/>
Commercial support is available at
<a href="http://nginx.com/">nginx.com</a>.</p>

<p><em>Thank you for using nginx.</em></p>
</body>
</html>
```

# Cleanup
Remove everything we created for this demo:

- Nginx service
- IP Pool created for this demo
- Nginx Deployment
- Nginx NameSpace (deleting the namespace would have deleted the deployment)
- Static route

```sh
kubectl delete -f nginx-svc.yaml
kubectl delete -f ippool.yaml
kubectl delete -f nginx-dp.yaml
kubectl delete -f nginx-ns.yaml
```

Delete the static route, if you added one:
```sh
sudo ip route delete 198.19.0.0/16
```

# References
[LoadBalancer IP Address Management (LB IPAM)](https://docs.cilium.io/en/stable/network/lb-ipam/)  
