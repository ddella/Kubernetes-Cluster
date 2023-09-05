# Kubernetes Ingress
In this tutorial we'll see how to configure a Kubernetes ingress service.

You will deploy the following:
- Demo App
- K8s **Ingress Resource Object**. It stores the HTTP routing rules
- K8s **Ingress Controller**. It's an actual Pod (Nginx, HAProxy, Traefik, ...) that uses the **Ingress Resource Object** to know how to route traffic

In this tutorial I'll be using Kubernetes Nginx Ingress Controller Community.

# Deploy a Demo Application
I will create three Kubernetes Deployments, each in it's own namespace. It will act as a demo application to test `Kubernetes Ingress`.

The app will answer on those `URLs` only, all other will throw an Nginx error:
- `/`: this returns the Pod hostname/IP address
- `/version/`: this a version number (can be used to test RollOut)
  - For `cURL`, add the flag `-L` if you use `/version`. Not needed for `/version/`
- `/type/`: this returns the deployment "color"
  - For `cURL`, add the flag `-L` if you use `/type`. Not needed for `/type/`

Create the NameSpaces, Deployments and the Services.

## Create NameSpace
Create a namespace to run a simple demo Deployment to test the Ingress:
```sh
NAMESPACE=blue-ns envsubst < 10-namespace.yaml | kubectl apply -f -
NAMESPACE=red-ns envsubst < 10-namespace.yaml | kubectl apply -f -
NAMESPACE=green-ns envsubst < 10-namespace.yaml | kubectl apply -f -
```

## Create Deployment
This is an example of of how to create three Deployments with the same `yaml` file.
```sh
COLOR=blue VERSION=1 envsubst < 11-deployment.yaml | kubectl apply -f -
COLOR=red VERSION=1 envsubst < 11-deployment.yaml | kubectl apply -f -
COLOR=green VERSION=1 envsubst < 11-deployment.yaml | kubectl apply -f -
```

## Create Service
```sh
COLOR=blue VERSION=1 envsubst < 12-service.yaml | kubectl apply -f -
COLOR=red VERSION=1 envsubst < 12-service.yaml | kubectl apply -f -
COLOR=green VERSION=1 envsubst < 12-service.yaml | kubectl apply -f -
```

## Add EXTERNAL-IP (DON'T DO THIS STEP)
In case you want to test your Apps, you can configure an `EXTERNAL-IP` to each service.
```sh
COLOR=blue && VERSION=1 && kubectl patch svc ${COLOR}-${VERSION}-svc -n ${COLOR}-ns -p '{"spec":{"externalIPs":["198.19.0.101"]}}'
COLOR=red && VERSION=1 && kubectl patch svc ${COLOR}-${VERSION}-svc -n ${COLOR}-ns -p '{"spec":{"externalIPs":["198.19.0.102"]}}'
COLOR=green && VERSION=1 && kubectl patch svc ${COLOR}-${VERSION}-svc -n ${COLOR}-ns -p '{"spec":{"externalIPs":["198.19.0.103"]}}'
```

## Check EndPoints (DON'T DO THIS STEP)
Every services created should have an EndPoint. Check to make sure your service has EndPoints:
```sh
COLOR=blue && VERSION=1 && kubectl get endpointslices -n ${COLOR}-ns -l service=${COLOR}-${VERSION}-svc
COLOR=red && VERSION=1 && kubectl get endpointslices -n ${COLOR}-ns -l service=${COLOR}-${VERSION}-svc
COLOR=green && VERSION=1 && kubectl get endpointslices -n ${COLOR}-ns -l service=${COLOR}-${VERSION}-svc
```

## Get Service IP (Optional)
The command returns the `CLUSTER-IP` of a service.
```sh
COLOR=blue && VERSION=1 && kubectl get services -n ${COLOR}-ns ${COLOR}-${VERSION}-svc -o go-template=$COLOR:\ '{{.spec.clusterIP}}{{"\n"}}'
COLOR=red && VERSION=1 && kubectl get services -n ${COLOR}-ns ${COLOR}-${VERSION}-svc -o go-template=$COLOR:\ '{{.spec.clusterIP}}{{"\n"}}'
COLOR=green && VERSION=1 && kubectl get services -n ${COLOR}-ns ${COLOR}-${VERSION}-svc -o go-template=$COLOR:\ '{{.spec.clusterIP}}{{"\n"}}'
```

# Installation Ingress-Nginx Controller
There are multiple ways to install the `Ingress-Nginx Controller`:

- with `Helm`, using the project repository chart;
- with `kubectl apply ...`, using YAML manifests;
- with specific addons (e.g. for minikube or MicroK8s).

## Quick start with `YAML` manifests file 
I will be using the `YAML` manifests file to create the Ingress-Nginx Controller.

1. Download the manifest file
2. Create the Deployment

### Step 1:
Get the latest version and download the manifest file with the commands:
```sh
VER=$(curl -s https://api.github.com/repos/kubernetes/ingress-nginx/releases/latest | grep tag_name | cut -d '"' -f 4)
echo ${VER}
curl -LO https://raw.githubusercontent.com/kubernetes/ingress-nginx/${VER}/deploy/static/provider/cloud/deploy.yaml
```

### Step 2:
Create the Deployment with the command:
```sh
kubectl create -f deploy.yaml
```
> [!NOTE]  
> It will install the controller in the `ingress-nginx` namespace, creating that namespace if it doesn't already exist.
>
> This command is **idempotent**:
>
> - if the ingress controller is not installed, it will install it,
> - if the ingress controller is already installed, it will upgrade it.
> The `YAML` manifest in the command above was generated with helm template, so you will end up with almost the same resources as if you had used Helm to install the controller.

## Pre-flight check
A few pods should start in the `ingress-nginx` namespace:
```sh
watch kubectl get pods -n ingress-nginx -l "'app.kubernetes.io/component in (controller, admission-webhook)'"
```

# Create Ingress Object
Let's create Ingress Object for our Demo Application created earlier.

<!-- The declarative way:
```sh
kubectl create ingress test-ingress -n ingress-ns \
--class=nginx --rule="ingress.isociel.com/*=demo:80"
``` -->

Or the imperative way:
```yaml
apiVersion: networking.k8s.io/v1
kind: Ingress
metadata:
  name: $COLOR-ingress
  namespace: $COLOR-ns
spec:
  ingressClassName: nginx
  rules:
  - host: $COLOR.isociel.com
    http:
      paths:
        - pathType: Prefix
          path: /
          backend:
            service:
              name: $COLOR-$VERSION-svc
              port:
                number: 80
```

```sh
COLOR=blue VERSION=1 envsubst < 13-ingress.yaml | kubectl apply -f -
COLOR=red VERSION=1 envsubst < 13-ingress.yaml | kubectl apply -f -
COLOR=green VERSION=1 envsubst < 13-ingress.yaml | kubectl apply -f -
```

## Local testing
Get the `CLUSTER-IP` and `EXTERNAL-IP` of the ingress service:
```sh
kubectl get service -n ingress-nginx ingress-nginx-controller
```

Output:
```
NAME                       TYPE        CLUSTER-IP     EXTERNAL-IP    PORT(S)          AGE
ingress-nginx-controller   ClusterIP   198.18.60.19   198.19.0.101   80/TCP,443/TCP   22h
```

Now, forward a local port `8080` to the ingress controller:
```sh
kubectl port-forward -n ingress-nginx service/ingress-nginx-controller 8080:80&
PF_PID=$!
```

> [!NOTE]  
>You need to be on a Kubernetes node part of the cluster to execute the `kubectl port-forwarding ...` command.

At this point, you can access your deployment using `cURL` with the commands:
```sh
COLOR=blue && curl --resolve ${COLOR}.isociel.com:8080:127.0.0.1 http://${COLOR}.isociel.com:8080
COLOR=red && curl --resolve ${COLOR}.isociel.com:8080:127.0.0.1 http://${COLOR}.isociel.com:8080
COLOR=green && curl --resolve ${COLOR}.isociel.com:8080:127.0.0.1 http://${COLOR}.isociel.com:8080
```

It also works with either the `CLUSTER-IP` or the `EXTERNAL-IP`:
```sh
COLOR=blue && curl --resolve ${COLOR}.isociel.com:80:198.18.60.19 http://${COLOR}.isociel.com/
COLOR=red && curl --resolve ${COLOR}.isociel.com:80:198.18.60.19 http://${COLOR}.isociel.com/
COLOR=green && curl --resolve ${COLOR}.isociel.com:80:198.18.60.19 http://${COLOR}.isociel.com/

COLOR=blue && curl --resolve ${COLOR}.isociel.com:80:198.19.0.101 http://${COLOR}.isociel.com/
COLOR=red && curl --resolve ${COLOR}.isociel.com:80:198.19.0.101 http://${COLOR}.isociel.com/
COLOR=green && curl --resolve ${COLOR}.isociel.com:80:198.19.0.101 http://${COLOR}.isociel.com/
```

> [!NOTE]  
>The `port-forwarding` mentioned above, is the easiest way to demo the working of ingress. The **"kubectl port-forward..."** command above has forwarded the port number `8080`, on the localhost's tcp/ip stack, where the command was typed, to the port number `80`, of the service created by the installation of ingress-nginx controller. So now, the traffic sent to port number `8080` on `localhost` will reach the port number `80`, of the ingress-controller's service. Port-forwarding is not for a production environment use-case. But here we use port-forwarding, to simulate a HTTP request, originating from outside the cluster, to reach the service of the ingress-nginx controller, that is exposed to receive traffic from outside the cluster.

Terminate the port forwarding we started above:
```sh
kill -SIGTERM -- -${PF_PID}
unset PF_PID
```

## External testing
If your Kubernetes cluster is a cluster that supports services of type `LoadBalancer` (CloudProvider), it will have allocated an `EXTERNAL-IP` address or FQDN to the ingress controller.

You can see that IP address or FQDN with the following command:
```sh
kubectl get service ingress-nginx-controller -n ingress-nginx
```

If the field `EXTERNAL-IP` shows <pending>, this means your Kubernetes cluster wasn't able to provision a load balancer. It's generally because it doesn't support services of type `LoadBalancer`, like an OnPrem Kubernetes Cluster started with `kubeadm`.
```
NAME                       TYPE           CLUSTER-IP     EXTERNAL-IP   PORT(S)                      AGE
ingress-nginx-controller   LoadBalancer   198.18.60.19   <pending>     80:30455/TCP,443:31046/TCP   47m
```

Add an `EXTERNAL-IP` to the `ingress-nginx-controller` service:
```sh
kubectl patch service ingress-nginx-controller -n ingress-nginx -p '{"spec":{"externalIPs":["198.19.0.101"]}}'
```

### DNS
Once you have the external IP address (or FQDN), set up a DNS record (or CNAME) pointing to it. Then you can create an ingress resource. In the following example, I've setup three DNS records for `${COLOR}.isociel.com`:

```sh
cat <<EOF | sudo tee -a /etc/hosts >/dev/null
198.19.0.101    blue.isociel.com
198.19.0.101    red.isociel.com
198.19.0.101    green.isociel.com
EOF
```

If you run an OnPrem K8s Cluster, you need to make the service of type `ClusterIP` instead of `LoadBalancer`:
```sh
kubectl patch service ingress-nginx-controller -n ingress-nginx -p '{"spec":{"type":"ClusterIP"}}'
```

After executing the command above, I now have an `EXTERNAL-IP`, that is routed inside my network and the type of the service is `ClusterIP`.
```
NAME                       TYPE        CLUSTER-IP     EXTERNAL-IP    PORT(S)          AGE
ingress-nginx-controller   ClusterIP   198.18.60.19   198.19.0.101   80/TCP,443/TCP   108m
```

You should then be able to see the page when you connect to http://${COLOR}.isociel.com/. It won't work with the IP address in the URL. You need a DNS entry or entry in the local `hosts` file.
```sh
COLOR=blue && curl http://${COLOR}.isociel.com/
COLOR=blue && curl -L http://${COLOR}.isociel.com/version
COLOR=blue && curl -L http://${COLOR}.isociel.com/type
```

Congratulations, you've setup an ingress service on an OnPrem Kubernetes cluster! 🎉 🎉 🎉

# Cleanup Demo App

## Delete NameSpace
If you delete the namespace, every objects associated with the namespace will also be deleted.
```sh
NAMESPACE=blue-ns envsubst < 10-namespace.yaml | kubectl delete -f -
NAMESPACE=red-ns envsubst < 10-namespace.yaml | kubectl delete -f -
NAMESPACE=green-ns envsubst < 10-namespace.yaml | kubectl delete -f -
```

> [!NOTE]  
> You can skip the rest, as all the services, deployments are deleted.

## Delete Service (Not needed if you deleted the nameSpace)
```sh
COLOR=blue && VERSION=1 && kubectl delete services -n ${COLOR}-ns ${COLOR}-${VERSION}-svc
COLOR=red && VERSION=1 && kubectl delete services -n ${COLOR}-ns ${COLOR}-${VERSION}-svc
COLOR=green && VERSION=1 && kubectl delete services -n ${COLOR}-ns ${COLOR}-${VERSION}-svc
```

## Delete EXTERNAL-IP (Not needed if you deleted the nameSpace)
In case you want to remove the `EXTERNAL-IP` to a service and want to keep the service, you can use the command:
```sh
COLOR=blue && VERSION=1 && kubectl patch svc ${COLOR}-${VERSION}-svc -n ${COLOR}-ns -p '{"spec":{"externalIPs":[]}}'
COLOR=red && VERSION=1 && kubectl patch svc ${COLOR}-${VERSION}-svc -n ${COLOR}-ns -p '{"spec":{"externalIPs":[]}}'
COLOR=green && VERSION=1 && kubectl patch svc ${COLOR}-${VERSION}-svc -n ${COLOR}-ns -p '{"spec":{"externalIPs":[]}}'
```

## Delete Deployment (Not needed if you deleted the nameSpace)
```sh
COLOR=blue && VERSION=1 && kubectl delete deployments -n ${COLOR}-ns ${COLOR}-${VERSION}-dp
COLOR=red && VERSION=1 && kubectl delete deployments -n ${COLOR}-ns ${COLOR}-${VERSION}-dp
COLOR=green && VERSION=1 && kubectl delete deployments -n ${COLOR}-ns ${COLOR}-${VERSION}-dp
```

# Cleanup Ingress Nginx
This command should delete every that was create here related to Ingress:
```sh
kubectl delete -f deploy.yaml
```

# References
[Kubernetes Ingress Tutorial For Beginners](https://devopscube.com/kubernetes-ingress-tutorial/)  
[How to Setup Nginx Ingress Controller On Kubernetes – Detailed Guide](https://devopscube.com/setup-ingress-kubernetes-nginx-controller/)  
[How To Configure Ingress TLS/SSL Certificates in Kubernetes](https://devopscube.com/configure-ingress-tls-kubernetes/)  
[Nginx ingress controller by kubernetes community](https://github.com/kubernetes/ingress-nginx)  
[Installation of Ingress-Nginx Controller](https://kubernetes.github.io/ingress-nginx/deploy/)  

# Troubleshooting Ingress
In this troubleshooting section, I completly skiped all the verification of the application (Deployment/Pods/Services). I'm focussing on the Kubernetes Ingress service only.

##  Describe the Ingress Controller
We are checking to make sure that the output here is routing to the correct service and Pods.
- Check that the `Type` is the one expected. For an OnPrem Cluster is should be `ClusterIP` and for a CloudProvider it should be `loadBalancer`
- Check the `External IPs:` is what is expected.
- Check that the `Endpoints: 100.127.210.116` is the IP address of the Ingress Controller Pods

```sh
kubectl describe service ingress-nginx-controller -n ingress-nginx
```

Output:
```
Name:              ingress-nginx-controller
Namespace:         ingress-nginx
Labels:            app.kubernetes.io/component=controller
                   app.kubernetes.io/instance=ingress-nginx
                   app.kubernetes.io/name=ingress-nginx
                   app.kubernetes.io/part-of=ingress-nginx
                   app.kubernetes.io/version=1.8.1
Annotations:       <none>
Selector:          app.kubernetes.io/component=controller,app.kubernetes.io/instance=ingress-nginx,app.kubernetes.io/name=ingress-nginx
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                198.18.60.19
IPs:               198.18.60.19
External IPs:      198.19.0.101
Port:              http  80/TCP
TargetPort:        http/TCP
Endpoints:         100.127.210.116:80
Port:              https  443/TCP
TargetPort:        https/TCP
Endpoints:         100.127.210.116:443
Session Affinity:  None
Events:            <none>
```

Get the IP address of the Ingress Controller Pod:
```sh
POD=$(kubectl get pods -n ingress-nginx --field-selector=status.phase==Running --no-headers -o custom-columns=":metadata.name")
kubectl get pods ${POD} -n ingress-nginx -o go-template='{{.status.podIP}}{{"\n"}}'
```

## Describe Ingress Service
We are checking to make sure that the output here is routing to the correct service and Pods.
- Check that the `Host` is the one expected.
- Check the `Backends` is pointing to the correct service and that the endpoints are the backend Pods.
- Check the `Path` for the expected URI.

```sh
COLOR=blue && kubectl describe ingress -n ${COLOR}-ns ${COLOR}-ingress
```

Output for one ingress:
```
Name:             blue-ingress
Labels:           <none>
Namespace:        blue-ns
Address:          198.18.60.19
Ingress Class:    nginx
Default backend:  <default>
Rules:
  Host              Path  Backends
  ----              ----  --------
  blue.isociel.com  
                    /   blue-1-svc:80 (100.104.19.129:80,100.127.210.124:80,100.81.189.123:80)
Annotations:        <none>
Events:             <none>
```

## Check the Logs
Get the logs of the Ingress Pod:
- Look for errors.
- Look for `GET` requests.

```sh
POD=$(kubectl get pods -n ingress-nginx --field-selector=status.phase==Running --no-headers -o custom-columns=":metadata.name")
kubectl logs ${POD} -n ingress-nginx | grep Error
```

> [!NOTE]  
> Use `kubectl logs -f ${POD} -n ingress-nginx` for realtime logs.

## Check Ingress Services
Check that the Ingress Pod has found all the Ingress Services you have configured:

Get All Ingress Service in every namespace:
```sh
kubectl get ingress -A
```

Output:
```
NAMESPACE   NAME            CLASS   HOSTS               ADDRESS        PORTS   AGE
blue-ns     blue-ingress    nginx   blue.isociel.com    198.18.60.19   80      82m
green-ns    green-ingress   nginx   green.isociel.com   198.18.60.19   80      84m
red-ns      red-ingress     nginx   red.isociel.com     198.18.60.19   80      82m
```

This should output as many lines (three in this example) as Ingress Service configured:
```sh
kubectl logs ${POD} -n ingress-nginx | grep "Found valid IngressClass"
```

Output:
```
I0904 15:21:52.260744       7 store.go:432] "Found valid IngressClass" ingress="blue-ns/blue-ingress" ingressclass="nginx"
I0904 15:21:52.261754       7 store.go:432] "Found valid IngressClass" ingress="green-ns/green-ingress" ingressclass="nginx"
I0904 15:21:52.263029       7 store.go:432] "Found valid IngressClass" ingress="red-ns/red-ingress" ingressclass="nginx"
```

## Describe the Service
Take a look at every Services of every Deployment.
- Look the IP address in the `Endpoints` field. It should be the list of your backing Pods.

```sh
COLOR=blue && VERSION=1 && kubectl describe service -n ${COLOR}-ns ${COLOR}-${VERSION}-svc
```

Output:
```
Name:              blue-1-svc
Namespace:         blue-ns
Labels:            color=blue-svc
                   service=blue-1-svc
Annotations:       <none>
Selector:          app=blue-1
Type:              ClusterIP
IP Family Policy:  SingleStack
IP Families:       IPv4
IP:                198.18.219.236
IPs:               198.18.219.236
Port:              <unset>  80/TCP
TargetPort:        80/TCP
Endpoints:         100.104.19.129:80,100.127.210.124:80,100.81.189.123:80
Session Affinity:  None
Events:            <none>
```

## Jump inside the Ingress Controller Pod
Jump inside the Ingress Controller Pod and run the `cURL` command to see what the Ingress will return. It should return the same HTTP data as if you'd be external.

```sh
POD=$(kubectl get pods -n ingress-nginx --field-selector=status.phase==Running --no-headers -o custom-columns=":metadata.name")
kubectl exec -it ${POD} -n ingress-nginx -- /bin/bash
```

Make a `GET` to a valid URI (here you're inside the Pod):
```sh
COLOR=blue && curl -H "HOST: ${COLOR}.isociel.com" http://localhost
COLOR=blue && curl -H "HOST: ${COLOR}.isociel.com" http://localhost/version/
```

> [!NOTE]  
> `cURL` option `-L Follow redirects` won't work here because the redirect will have an FQDN that the Pod can't resolve.

See below for the return data from `cURL` and verify that is what you expect.

Output:
```
Hello World, from blue Pod version: 1 [blue-1-dp-7f44b859d7-nzs9r] at IP [100.81.189.123]: Mon Sep  4 15:42:04 UTC 2023
```

## Final Test
On an external station from the K8s Cluster.

Make sure you have a route for the external IP address of your load balancer:
```sh
netstat -rn | grep 198.19.0
ip route get 198.19.0.0/24
```

Make sure you have DNS resolution:
```sh
COLOR=blue && ping ${COLOR}.isociel.com
```

> [!NOTE]  
> `ping` won't work on a K8s Service but you will see the IP address of the service. `dig` and `nslookup` will query your DNS but if you just added an entry in your `/etc/hosts` it won't return the IP.


If you want to use the IP address in the URL, make sure you add the header `HOST: ...` or it won't work, remember we're at layer 7 here.
- You have a DNS entry
- You don't have a DNS entry
- You want to use the IP address

```sh
COLOR=blue && curl --connect-timeout 3 http://${COLOR}.isociel.com
COLOR=blue && curl --resolve ${COLOR}.isociel.com:80:198.19.0.101 http://${COLOR}.isociel.com/
COLOR=blue && curl --connect-timeout 3 -H "HOST: ${COLOR}.isociel.com" http://198.19.0.101
```
