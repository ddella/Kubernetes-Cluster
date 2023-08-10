# Most Common Kubernetes Deployment Strategies (Examples & Code)

### Rolling Update  
![](images/rolling-update.jpg)  

### Recreate  
![](images/recreate.jpg)

### Blue/Green  
![](images/blue-green.jpg)

### Canary  
![](images/canary.jpg)

### Shadow  
![](images/shadow.jpg)

### A/B Testing  
![](images/a-b-testing.jpg)  

# Rolling Update
Gradually replaces old Pods with new ones.

## Start a Deployment
Start a Deployment with the default rolling update. Our demo app is at version 1.
```bash
kubectl create -f 1-rolling-update.yaml 
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
kubectl replace -f 1-rolling-update.yaml
```

You should gradually start seeing 2 versions. After some time, all the Pods will be at version 2.
```
{"version":"v1"}
{"version":"v1"}
{"version":"v2"}
{"version":"v1"}
{"version":"v1"}
{"version":"v2"}
{"version":"v1"}
{"version":"v1"}
```

## Roll Out
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

We have only one:
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

We are now back at version 1.

# References
[Anton Putra - Most Common Kubernetes Deployment Strategies](https://www.youtube.com/watch?v=lxc4EXZOOvE)  
[Anton Putra - GitHub](https://github.com/antonputra/tutorials/tree/main/lessons/171)  
