# Test Cilium Installation
Let's get our hands dirty and try a simple deployment on our new Kubernetes Cluster. We'll deploy three Nginx Pods with a simple service.

# Create NameSpace
Create a separate namespace for our Nginx deployment with the command:
```sh
cat <<EOF > nginx-ns.yaml 
kind: Namespace
apiVersion: v1
metadata:
  name: nginx-ns
  labels:
    name: nginx-ns
EOF
```

```sh
kubectl create -f nginx-ns.yaml
```

# Create Deployment
Create a separate namespace for our Nginx deployment with the command:
```sh
cat <<EOF > nginx-dp.yaml 
apiVersion: apps/v1
kind: Deployment
metadata:
  name: nginx-test
  namespace: nginx-ns
spec:
  selector:
    matchLabels:
      run: nginx-test
  replicas: 3
  template:
    metadata:
      labels:
        run: nginx-test
    spec:
      containers:
      - name: nginx-test
        image: nginx
        ports:
        - containerPort: 80
EOF
```

```sh
kubectl create -f nginx-dp.yaml
```

# Check the Deployment
```sh
kubectl get pods -n nginx-ns -o wide
```

### Check that the IP's given to the Pods fall in the `podSubnet` configured when you bootstrapped the cluster:
```
NAME                          READY   STATUS    RESTARTS   AGE   IP             NODE                     NOMINATED NODE   READINESS GATES
nginx-test-65689bc694-9gb68   1/1     Running   0          46s   100.64.1.194   k8sworker1.isociel.com   <none>           <none>
nginx-test-65689bc694-9j9qh   1/1     Running   0          46s   100.64.3.79    k8sworker3.isociel.com   <none>           <none>
nginx-test-65689bc694-vnbzp   1/1     Running   0          46s   100.64.2.92    k8sworker2.isociel.com   <none>           <none>
```

# Create a Service
Create a separate namespace for our Nginx deployment with the command:
```sh
cat <<EOF > nginx-svc.yaml 
apiVersion: v1
kind: Service
metadata:
  name: nginx-svc
  namespace: nginx-ns
  labels:
    run: nginx-svc
    color: red
spec:
  type: LoadBalancer
  ports:
  - port: 80
    protocol: TCP
  selector:
    run: nginx-test
EOF
```

```sh
kubectl create -f nginx-svc.yaml
```

### Check that the service as been created and that the IP address assign to it falls in the `serviceSubnet` configured when you bootstrapped the cluster:
```sh
kubectl get svc -n nginx-ns
```

```
NAME        TYPE           CLUSTER-IP      EXTERNAL-IP   PORT(S)        AGE
nginx-svc   LoadBalancer   198.19.62.222   <pending>     80:30531/TCP   17s
```

>You can only reach the `CLUSTER-IP` from a node within the cluster or you can use any other server but it needs to have a static IP address to reach that IP address. We'll see later how to enable BGP to advertise that IP to a `TOR` router.

You can check [this](08-BGP.md) tutorial on how to active BGP with Cilium. Leave everything you've done here running.
