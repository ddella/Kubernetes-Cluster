# Deployment

Example of a K8s Deployment template.

## Create a NameSpace

    kubectl create -f alpine-ns.yaml

## Create the Deployment

    kubectl create -f alpine-dp.yaml

## Get the pods list

    kubectl get pods -o wide -n alpine
    
    NAME                                 READY   STATUS    RESTARTS   AGE   IP              NODE                     NOMINATED NODE   READINESS GATES
    alpine-deployment-7b94455bbd-2n4qj   1/1     Running   0          10m   10.255.77.133   k8sworker1.isociel.com   <none>           <none>
    alpine-deployment-7b94455bbd-d79j9   1/1     Running   0          10m   10.255.153.95   k8sworker2.isociel.com   <none>           <none>
    alpine-deployment-7b94455bbd-n57fb   1/1     Running   0          10m   10.255.18.183   k8sworker3.isociel.com   <none>           <none>

## Describe the pod

    kubectl describe pod alpine-deployment -n alpine

## Get the Deployment info

    kubectl get deploy -n alpine -o=wide

    NAME                READY   UP-TO-DATE   AVAILABLE   AGE   CONTAINERS   IMAGES          SELECTOR
    alpine-deployment   3/3     3            3           13m   alpine       alpine:3.18.2   app=alpine

    kubectl describe deploy -n alpine alpine-deployment

## Get the ReplicaSet name

    kubectl get rs -n alpine

## Describe the ReplicaSet

    kubectl describe rs -n alpine

## Check the local registry for the image

    sudo nerdctl --namespace=k8s.io image ls | grep alpine

>**Note**: On the Master node, the command returns an empty string, since the image is pulled on worker nodes only

## Jump inside the first container

    kubectl exec -it $(kubectl get pods -n alpine -o=name | head -1) -n alpine -- /bin/sh

## Cleanup

    kubectl delete -f alpine-ns.yaml