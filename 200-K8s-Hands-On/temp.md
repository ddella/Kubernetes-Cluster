```sh
kubectl patch svc myapp -n test -p '{"spec":{"externalIPs":["198.19.0.100"]}}'
```

```
service/myapp patched
```

```sh
kubectl get svc -n test
```

```
NAME    TYPE           CLUSTER-IP       EXTERNAL-IP    PORT(S)          AGE
myapp   LoadBalancer   198.18.116.202   198.19.0.100   8181:30502/TCP   14m
```

```sh
kubectl patch svc myapp -n test -p '{"spec":{"externalIPs":[]}}'
```

```
service/myapp patched
```

```sh
kubectl get svc -n test
```

```
NAME    TYPE           CLUSTER-IP       EXTERNAL-IP   PORT(S)          AGE
myapp   LoadBalancer   198.18.116.202   <pending>     8181:30502/TCP   24m
```

---

```sh
kubectl expose deployment blue-myapp -n test --type=LoadBalancer --name=myapp --external-ip=198.19.0.100
```

```sh
kubectl delete svc -n test myapp
```

```yaml
kubectl apply -f - <<EOF
apiVersion: v1
kind: Service
metadata:
  name: myapp
  namespace: test
  labels:
    run: myapp-svc
    replica: blue
    color: blue
spec:
  selector:
    app: myapp
    replica: blue
  type: LoadBalancer
  ports:
  - port: 8181
    protocol: TCP
    targetPort: http
  externalIPs:
    - 198.19.0.100
EOF
```

## On the Jump
To reach the external IP, you need a routing protocol like BGP or a static IP address. Let's use a static route:
```sh
# On a Ubuntu jump station
sudo ip route add 198.19.0.0/24 via 192.168.13.61
curl http://198.19.0.100:8181/version
```

Output:
```
{"version":"v1"}
```

Remove the static route:
```sh
sudo ip route del 198.19.0.0/24
```
