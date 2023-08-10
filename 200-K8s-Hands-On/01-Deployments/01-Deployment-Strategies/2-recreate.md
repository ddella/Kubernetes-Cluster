# Kubernetes Recreate Deployment Strategy (Examples & Code)
With this type of deployment, all existing Pods are deleted before new Pods are created. This **WILL** cause a downtime.

- Limited ressources on a Node
- Mount Volume to a single Pod

### Rolling Update  
![](images/recreate%20copy.jpg)  

## Start a Deployment
Start a Deployment with the type `recreate`. Our demo app is at version 1.
```bash
kubectl create -f 2-recreate.yaml
```

Start a test Pod with an image that has `cURL`:
```bash
kubectl run curl --image=alpine/curl:8.2.1 -n kube-system -it --rm -- /bin/sh
while true; do curl myapp.test:8181/version; echo ""; sleep 1; done
```

> [!NOTE]  
> Hit <kbd>Ctrl</kbd> + <kbd>C</kbd> to stop the `while` loop.

## Rolling Update

Edit the `yaml` file and replace the image with version 2.
```yaml
      containers:
        - name: myapp
          image: aputra/myapp-171:v2
```

Start the rolling update by replacing the `yaml` file. Our demo app will be replaced by the one with version 2.
```sh
kubectl replace -f 2-recreate.yaml
```

Now this time the replacement wasn't gradually. We had a downtime while all the Pods were deleted. After all Pods were created, the service came back.
```
{"version":"v1"}
{"version":"v1"}
curl: (7) Failed to connect to 192.0.2.199 port 8181 after 2 ms: Connection refused

{"version":"v2"}
{"version":"v2"}
```

## Undo
Check the last status of the deployment:
```sh
kubectl rollout -n test status deploy/myapp
```

It was successfull:
```
deployment "myapp" successfully rolled out
```

Check the history of the deployment:
```sh
kubectl rollout -n test history deploy/myapp
```

We have two. The first is the deployment of version 1 and the second is the deployment of version 2:
```
deployment.apps/myapp 
REVISION  CHANGE-CAUSE
1         <none>
2         <none>
```

Let's pretend that we have problems with version 2 and we want to go back to version 1 😉
```sh
kubectl rollout -n test undo deployment/myapp
```

```
deployment.apps/myapp rolled back
```

We are now back at version 1 and we had the same behavior as the previous deployment, a downtime.

```
{"version":"v2"}
{"version":"v2"}
curl: (7) Failed to connect to 192.0.2.199 port 8181 after 2 ms: Connection refused

{"version":"v1"}
{"version":"v1"}
```

# Cleanup
Remove everything we created:
```sh
kubectl delete -f 2-recreate.yaml
```

# References
[Anton Putra - Most Common Kubernetes Deployment Strategies](https://www.youtube.com/watch?v=lxc4EXZOOvE)  
[Anton Putra - GitHub](https://github.com/antonputra/tutorials/tree/main/lessons/171)  
