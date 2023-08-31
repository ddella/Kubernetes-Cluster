# Echo Server
Simple `DaemonSet` with nginx anwsering on TCP/80 and returning the hostname and IP address of the Pod.

The external TCP port is 8181 and the Nginx servers listen on port 80.

## Step1: Create the namespace

```sh
kubectl create -f 1-namespace.yaml
```

## Step 2: Create the DaemonSet

```sh
kubectl create -f 2-DaemonSet.yaml
```

## Step 3: Create the Service

```sh
kubectl create -f 3-service.yaml
```

# Tests

## Pods
```sh
kubectl get pods -n echo-server -o wide
```

```
NAME                READY   STATUS    RESTARTS   AGE    IP               NODE                     NOMINATED NODE   READINESS GATES
echo-server-7gtcf   2/2     Running   0          106m   100.127.210.17   k8sworker2.isociel.com   <none>           <none>
echo-server-l69r9   2/2     Running   0          106m   100.104.19.21    k8sworker1.isociel.com   <none>           <none>
echo-server-twmts   2/2     Running   0          106m   100.81.189.19    k8sworker3.isociel.com   <none>           <none>
```

## Service
```sh
kubectl describe service -n echo-server echo-server
```

Output:
```
Name:              echo-server
Namespace:         echo-server
Labels:            <none>
Annotations:       <none>
Selector:          name=my-ds
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                198.18.198.46
IPs:               198.18.198.46
External IPs:      198.19.0.100
Port:              <unset>  8181/TCP
TargetPort:        80/TCP
Endpoints:         100.104.19.21:80,100.127.210.17:80,100.81.189.19:80
Session Affinity:  None
Events:            <none>
```


## Web Server
From any K8s cluster node, you can do the following:
```sh
while true; do curl http://198.19.0.100:8181; sleep 1; done
```

> [!IMPORTANT]  
> To test it from any station, make sur you have a route (static or dynamic) for the external IP address pointing to any node in the K8s cluster.
> sudo ip route add 198.19.0.0/24 via 192.168.13.65
> sudo ip route del 198.19.0.0/24

# Cleanup

```sh
kubectl delete -f 3-service.yaml
kubectl create -f 2-DaemonSet.yaml
kubectl create -f 1-namespace.yaml
```

> [!NOTE]  
> Deleting the namespace is sufficient.
