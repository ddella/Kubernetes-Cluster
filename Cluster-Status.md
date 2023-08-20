# Kubernetes Health
The Kubernetes API server provides 3 API endpoints (healthz, livez and readyz) to indicate the current status of the API server. The `healthz` endpoint is deprecated (since Kubernetes v1.16), and you should use the more specific `livez` and `readyz` endpoints instead. The `livez` endpoint can be used with the `--livez-grace-period` flag to specify the startup duration. For a graceful shutdown you can specify the `--shutdown-delay-duration` flag with the `/readyz` endpoint. Machines that check the `healthz/livez/readyz` of the API server should rely on the HTTP status code. A status code 200 indicates the API server is `healthy/live/ready`, depending on the called endpoint. The more verbose options are intended to be used by human operators to debug their cluster or understand the state of the API server.

## Get API Server URL
Get the URL of your cluster API server:
```sh
APISERVER=$(kubectl config view -o go-template='{{range .clusters}}{{.cluster.server}}{{"\n"}}{{end}}')
echo ${APISERVER}
```

> [!NOTE]  
> The command `curl -k ${APISERVER}/version` can be replaced by `kubectl get --raw='/version'`, if you don't have `cURL` installed locally.
> The command `kubectl get --raw='/version'` has the advantages of having your request authenticated, if you have the right file `~/.kube/config`

## Health endpoints
[Kubernetes API health endpoints](https://kubernetes.io/docs/reference/using-api/health-checks/)  

Use this command to check the status of all the cluster components:
```sh
kubectl get --raw='/readyz?verbose'
```

The same command but with `cURL`:
```sh
curl -k ${APISERVER}/livez?verbose
```

Get the cluster version:
```sh
curl -k ${APISERVER}/version
```