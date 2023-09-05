# Grafana

# Username and Password
We can find the username and password required to log in into Grafana using the following commands. It will show the values in encrypted format, which we can decode using OpenSSL and base 64 formats.

Get the information of the Grafana secret. The username and password in base64 encoded:
```sh
kubectl get secret -n prometheus prometheus-grafana -o yaml
```

Output:
```yaml
apiVersion: v1
data:
  admin-password: cHJvbS1vcGVyYXRvcg==
  admin-user: YWRtaW4=
  ldap-toml: ""
kind: Secret
metadata:
  annotations:
    meta.helm.sh/release-name: prometheus
    meta.helm.sh/release-namespace: default
  creationTimestamp: "2023-08-30T23:53:43Z"
  labels:
    app.kubernetes.io/instance: prometheus
    app.kubernetes.io/managed-by: Helm
    app.kubernetes.io/name: grafana
    app.kubernetes.io/version: 10.1.0
    helm.sh/chart: grafana-6.59.0
  name: prometheus-grafana
  namespace: prometheus
  resourceVersion: "218887"
  uid: f23c9c34-9e54-49cd-ad92-c7198aaf4e0d
type: Opaque
```

# Decode Username and Password
The `username` and `password` in the secret are Base64 encoded.

You can get the `username` and `password` by parsing the output of the `json-path`:
```sh
kubectl get secret -n prometheus prometheus-grafana -o jsonpath='{.data.admin-user}' | base64 -d; echo
kubectl get secret -n prometheus prometheus-grafana -o jsonpath='{.data.admin-password}' | base64 -d; echo
```

Same but with a `go-template`
```sh
kubectl get secret -n prometheus prometheus-grafana -o go-template='{{range $k,$v := .data}}{{printf "%s: " $k}}{{if not $v}}{{$v}}{{else}}{{$v | base64decode}}{{end}}{{"\n"}}{{end}}'
```

# Access Grafana

```url
http://198.19.0.91/login
```

