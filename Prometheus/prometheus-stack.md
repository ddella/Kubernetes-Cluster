# K8s Cluster Monitoring with Prometheus
We are going to show how to install Prometheus and Grafana using Helm charts. We are also going to learn how we can connect Prometheus and Grafana together and set up a basic dashboard on Grafana to monitor resources on the Kubernetes cluster.

Prometheus takes care of data fetching as a data source and feeds that data into Grafana which is used to visualize data with attractive dashboards.

# kube-prometheus-stack
Installs the kube-prometheus stack, a collection of Kubernetes manifests, Grafana dashboards, and Prometheus rules combined with documentation and scripts to provide easy to operate end-to-end Kubernetes cluster monitoring with Prometheus using the Prometheus Operator.

See the kube-prometheus README for details about components, dashboards, and alerts.

Note: This chart was formerly named prometheus-operator chart, now renamed to more clearly reflect that it installs the kube-prometheus project stack, within which Prometheus Operator is only one component.

# Get Helm Repository Info
Get Repository Info:
```sh
helm repo add prometheus-community https://prometheus-community.github.io/helm-charts
helm repo update
```

# Install Prometheus
I'll use `helm` to install Prometheus. If you don't have Helm installed, follow this quick tutorial [here](../helm.md)

### Check the version available on Helm (Optional):
```sh
helm show chart prometheus-community/prometheus | grep ^appVersion
```

### Customize Chart Values
Get the values of the chart: 
```sh
helm show values prometheus-community/kube-prometheus-stack > values.yaml
```

I prefer running Prometheus in it's own namespace:
```
## Override the deployment namespace
##
namespaceOverride: "prometheus"
...
## Using default values from https://github.com/grafana/helm-charts/blob/main/charts/grafana/values.yaml
##
grafana:
  enabled: true
  namespaceOverride: "prometheus"
...
## Configuration for kube-state-metrics subchart
##
kube-state-metrics:
  namespaceOverride: "prometheus"
...
## Configuration for prometheus-node-exporter subchart
##
prometheus-node-exporter:
  namespaceOverride: "prometheus"
```

### Install Prometheus with a customized configuration:
```sh
kubectl create namespace prometheus
helm install prometheus prometheus-community/kube-prometheus-stack -f values.yaml
```

Output:
```
NAME: prometheus
LAST DEPLOYED: Mon Aug 14 08:54:30 2023
NAMESPACE: default
STATUS: deployed
REVISION: 1
NOTES:
kube-prometheus-stack has been installed. Check its status by running:
  kubectl --namespace prometheus get pods -l "release=prometheus"

Visit https://github.com/prometheus-operator/kube-prometheus for instructions on how to create & configure Alertmanager and Prometheus instances using the Operator.
```

# Verify Installation
```sh
kubectl get all -n prometheus
```

Output:
```
NAME                                                         READY   STATUS    RESTARTS   AGE
pod/alertmanager-prometheus-kube-prometheus-alertmanager-0   2/2     Running   0          37s
pod/prometheus-grafana-5b4b87769c-zkfz7                      3/3     Running   0          49s
pod/prometheus-kube-prometheus-operator-6c676cfb6b-ffcsq     1/1     Running   0          49s
pod/prometheus-kube-state-metrics-7f4f499cb5-24dhz           1/1     Running   0          49s
pod/prometheus-prometheus-kube-prometheus-prometheus-0       2/2     Running   0          36s
pod/prometheus-prometheus-node-exporter-7cdq9                1/1     Running   0          49s
pod/prometheus-prometheus-node-exporter-dc7wr                1/1     Running   0          49s
pod/prometheus-prometheus-node-exporter-h76xl                1/1     Running   0          49s
pod/prometheus-prometheus-node-exporter-qkjps                1/1     Running   0          49s

NAME                                              TYPE        CLUSTER-IP       EXTERNAL-IP   PORT(S)                      AGE
service/alertmanager-operated                     ClusterIP   None             <none>        9093/TCP,9094/TCP,9094/UDP   37s
service/prometheus-grafana                        ClusterIP   198.19.176.7     <none>        80/TCP                       49s
service/prometheus-kube-prometheus-alertmanager   ClusterIP   198.19.209.242   <none>        9093/TCP,8080/TCP            49s
service/prometheus-kube-prometheus-operator       ClusterIP   198.19.171.201   <none>        443/TCP                      49s
service/prometheus-kube-prometheus-prometheus     ClusterIP   198.19.188.7     <none>        9090/TCP,8080/TCP            49s
service/prometheus-kube-state-metrics             ClusterIP   198.19.181.191   <none>        8080/TCP                     49s
service/prometheus-operated                       ClusterIP   None             <none>        9090/TCP                     37s
service/prometheus-prometheus-node-exporter       ClusterIP   198.19.7.36      <none>        9100/TCP                     49s

NAME                                                 DESIRED   CURRENT   READY   UP-TO-DATE   AVAILABLE   NODE SELECTOR            AGE
daemonset.apps/prometheus-prometheus-node-exporter   4         4         4       4            4           kubernetes.io/os=linux   49s

NAME                                                  READY   UP-TO-DATE   AVAILABLE   AGE
deployment.apps/prometheus-grafana                    1/1     1            1           49s
deployment.apps/prometheus-kube-prometheus-operator   1/1     1            1           49s
deployment.apps/prometheus-kube-state-metrics         1/1     1            1           49s

NAME                                                             DESIRED   CURRENT   READY   AGE
replicaset.apps/prometheus-grafana-5b4b87769c                    1         1         1       49s
replicaset.apps/prometheus-kube-prometheus-operator-6c676cfb6b   1         1         1       49s
replicaset.apps/prometheus-kube-state-metrics-7f4f499cb5         1         1         1       49s

NAME                                                                    READY   AGE
statefulset.apps/alertmanager-prometheus-kube-prometheus-alertmanager   1/1     37s
statefulset.apps/prometheus-prometheus-kube-prometheus-prometheus       1/1     37s
```

---
# Uninstall Helm Chart (just in case 😀)
If you ever want to uninstall Prometheus completely, use the commands below (deleting the namespace should be sufficient):
```sh
helm uninstall prometheus
kubectl delete ns prometheus
```
CRDs created by this chart are not removed by default and should be manually cleaned up:
```sh
kubectl delete crd alertmanagerconfigs.monitoring.coreos.com
kubectl delete crd alertmanagers.monitoring.coreos.com
kubectl delete crd podmonitors.monitoring.coreos.com
kubectl delete crd probes.monitoring.coreos.com
kubectl delete crd prometheusagents.monitoring.coreos.com
kubectl delete crd prometheuses.monitoring.coreos.com
kubectl delete crd prometheusrules.monitoring.coreos.com
kubectl delete crd scrapeconfigs.monitoring.coreos.com
kubectl delete crd servicemonitors.monitoring.coreos.com
kubectl delete crd thanosrulers.monitoring.coreos.com
```

You shouldn't see anything in the namespace `prometheus`
```sh
kubectl get all -n prometheus
```

## If you want to remove the images, go on each node (master and worker) and:
1. List the image(s)

List the local images:
```sh
crictl images ls
```

The ouput should look like this:
```
IMAGE                                                    TAG                 IMAGE ID            SIZE
...
quay.io/prometheus-operator/prometheus-config-reloader   v0.65.1             27473df42d72c       5.2MB
quay.io/prometheus/alertmanager                          v0.25.0             c8568f914cd25       30.8MB
quay.io/prometheus/node-exporter                         v1.5.0              0da6a335fe135       11.5MB
quay.io/prometheus/prometheus                            v2.44.0             75972a31ad256       93MB
...
```

2. Delete the image(s) with the command:
```sh
crictl rmi <IMAGE ID>
```
# References
[Kubernetes Monitoring Made Easy with Prometheus | KodeKloud](https://www.youtube.com/watch?v=6xmWr7p5TE0)  
[helm-charts](https://github.com/prometheus-community/helm-charts)  
[kube-prometheus-stack](https://github.com/prometheus-community/helm-charts/blob/main/charts/kube-prometheus-stack/README.md)  
[kube-prometheus](https://github.com/prometheus-operator/kube-prometheus)  
