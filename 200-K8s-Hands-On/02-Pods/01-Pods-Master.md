# Pods on Control Plane
Force a Pod to run on the Control Plane:
```yaml
apiVersion: v1
kind: Pod
metadata:
  labels:
    run: nginxpod
  name: nginxpod
spec:
  # Force to run on a specific node
  nodeName: k8smaster1.isociel.com
  containers:
  - image: nginx
    name: nginxpod
    resources: {}
  dnsPolicy: ClusterFirst
  restartPolicy: Always
status: {}
```
