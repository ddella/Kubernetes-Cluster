# Add Service
Add a service for the Pod from the previous example:
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    run: nginxpod
  name: nginxsvc
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    run: nginxpod
status:
  loadBalancer: {}
```

# Add Service with NodePort
Add a service, with NodePort, for the Pod from the previous example:
```yaml
apiVersion: v1
kind: Service
metadata:
  labels:
    run: nginxpod
  name: nginxnodeportsvc
spec:
  ports:
  - port: 80
    protocol: TCP
    targetPort: 80
  selector:
    run: nginxpod
  type: NodePort
status:
  loadBalancer: {}
```
