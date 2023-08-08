# Service Accounts
This page introduces the `ServiceAccount` object in Kubernetes, providing information about how service accounts work, use cases, limitations, alternatives, and links to resources for additional guidance.

Accessing Kubernetes clusters by human has always been straightforward. You only need to download a `kubeconfig` file and place it in `$HOME/.kube/config` for your `kubectl` tool to read it. This works well for human access, but there are use cases when you'd like some tools to access your Kubernetes API server. For example, your CI/CD pipeline somehow needs to authenticate to your cluster in order to deploy your applications there. For **non-human access**, Kubernetes offers what it calls service accounts. In this post, you'll learn what they are and how to use them.

# What are service accounts?
A service account is a type of *non-human* account that, in Kubernetes, provides a distinct identity in a Kubernetes cluster. Application Pods, system components, and entities inside and outside the cluster can use a specific ServiceAccount's credentials to identify as that ServiceAccount. This identity is useful in various situations, including authenticating to the API server or implementing identity-based security policies.

Service accounts exist as `ServiceAccount` objects in the API server. Service accounts have the following properties:

- **Namespaced**: Each service account is bound to a Kubernetes namespace. Every namespace gets a default ServiceAccount upon creation.

- **Lightweight**: Service accounts exist in the cluster and are defined in the Kubernetes API. You can quickly create service accounts to enable specific tasks.

- **Portable**: A configuration bundle for a complex containerized workload might include service account definitions for the system's components. The lightweight nature of service accounts and the namespaced identities make the configurations portable.

Service accounts are different from user accounts, which are authenticated human users in the cluster. By default, user accounts don't exist in the Kubernetes API server; instead, the API server treats user identities as opaque data. You can authenticate as a user account using multiple methods. Some Kubernetes distributions might add custom extension APIs to represent user accounts in the API server.

# Default service accounts
When you create a cluster, Kubernetes automatically creates a `ServiceAccount` object named default for every namespace in your cluster. The default service accounts in each namespace get no permissions by default other than the default API discovery permissions that Kubernetes grants to all authenticated principals if role-based access control (RBAC) is enabled. If you delete the default ServiceAccount object in a namespace, the control plane replaces it with a new one.

If you deploy a Pod in a namespace, and you don't manually assign a ServiceAccount to the Pod, Kubernetes assigns the default ServiceAccount for that namespace to the Pod.

# Get Service Account
The shorthand for `serviceaccount` is `sa`. You can use either with `kubectl` command like below:

List the SA in a name space:
```sh
kubectl get serviceaccount -n nginx-ns
```

Output:
```
NAME      SECRETS   AGE
default   0         23h
```

```sh
kubectl get sa -n nginx-ns default -o yaml
```

Output:
```
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: "2023-08-04T14:07:21Z"
  name: default
  namespace: nginx-ns
  resourceVersion: "5402"
  uid: f80471b9-f0a8-470a-83b3-32a9dcfb32ca
```

# Create Service Account
This section will show how to create a service account. By default, it won't have any permissions associated with it. In other words, it won't be able to do anything. We'll see later that you need to create a role binding for your new service account to an existing Kubernetes role or create a new custom role.

### Imperative Way
Create a service acccount the `imperative way`:
```sh
kubectl create -n nginx-ns serviceaccount sa1
```

```sh
kubectl get sa -n nginx-ns sa1 -o yaml
```

Output:
```
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: "2023-08-05T13:33:31Z"
  name: sa1
  namespace: nginx-ns
  resourceVersion: "182061"
  uid: 6dc198ad-eeed-40a2-bee5-069f881ee273
```

### Declarative Way
Create a service acccount the `declarative way`:
```yaml
cat <<EOF > sa1.yaml
apiVersion: v1
kind: ServiceAccount
metadata:
  name: sa1
  namespace: nginx-ns
EOF
```

```sh
kubectl create -f sa1.yaml
```

```sh
kubectl get sa -n nginx-ns sa1 -o yaml
```

Output:
```
apiVersion: v1
kind: ServiceAccount
metadata:
  creationTimestamp: "2023-08-05T13:43:15Z"
  name: sa1
  namespace: nginx-ns
  resourceVersion: "183287"
  uid: 2bf6fcf2-cca9-483e-939b-fcf00e7e288f
```

# Assign ServiceAccount to a Pod
After you have created `ServiceAccount`, you can start assigning them to pods. You use `spec.serviceAccountName` field in the Pod's definition to assign a `ServiceAccount`. Here I am creating a simple Nginx pod and I assign ServiceAccount `sa1` to it.

Create a simple Alpine Pod in a namespace and assign `sa1` to it:
```yaml
cat <<EOF > nginx-pod.yaml
apiVersion: v1
kind: Pod
metadata:
  name: nginx-sa
  namespace: nginx-ns
spec:
  serviceAccount: sa1
  containers:
  - name: nginx-sa
    image: nginx
    ports:
    - containerPort: 80
EOF
```

```sh
kubectl create -f nginx-pod.yaml
```

### K8s API Server
If we try to access Kubernetes API server, with a normal account, from the new Pod, we get an HTTP 403 - Forbidden for user anonymous:

Jump inside the Pod:
```sh
kubectl exec -it -n nginx-ns nginx-sa -- /bin/sh
```

Try to access K8s API server with anonymous user account:
```sh
curl --insecure https://kubernetes.default.svc/api/v1/namespaces/nginx-ns/pods
```

Output:
```
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "pods is forbidden: User \"system:anonymous\" cannot list resource \"pods\" in API group \"\" in the namespace \"nginx-ns\"",
  "reason": "Forbidden",
  "details": {
    "kind": "pods"
  },
  "code": 403
}
```

If we try to access Kubernetes API server, with our secret token of `sa1` ServiceAccount along with the CA certificate inside the serviceaccount directory, from the new Pod, we get an HTTP 403 - Forbidden for user `sa1`:
```sh
curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes.default.svc/api/v1/namespaces/nginx-ns/pods
```

>[K8s API OVERVIEW](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.27/#pod-v1-core)

Output:
```
{
  "kind": "Status",
  "apiVersion": "v1",
  "metadata": {},
  "status": "Failure",
  "message": "pods is forbidden: User \"system:serviceaccount:nginx-ns:sa1\" cannot list resource \"pods\" in API group \"\" in the namespace \"nginx-ns\"",
  "reason": "Forbidden",
  "details": {
    "kind": "pods"
  },
  "code": 403
}
```
 Let's disect the error message:
 - API group "": API group is blank, that means it's for Pods
 - pods is forbidden: It's a `pods` ressource
 - User "system:serviceaccount:nginx-ns:sa1": We know it's a `serviceaccount`, in namespace `nginx-ns` and the name is `sa1`
 - cannot list: So the verb is `list`

We're trying to `list` Pods in namespace `nginx-ns` with a `serviceaccount` named `sa1`.

With this information, we can build our Role are RoleBinding.

# Create Role
We create a `Role` based on the error we got above:
```yaml
cat <<EOF > role.yaml
apiVersion: rbac.authorization.k8s.io/v1
kind: Role
metadata:
  namespace: nginx-ns # Error was for namespace "nginx-ns"
  name: sa1-list
rules:
- apiGroups: [""] # "" API group was blank
  resources: ["pods"] # Ressource is "ods"
  verbs: ["list"] # Verb is "list"
EOF
```

Let's create the Role in the namespace `nginx-ns`:
```sh
kubectl create -n nginx-ns -f role.yaml
```

>That won't give our service account access yet. We need to bind the account to that Role.

# Create Role Binding
A role binding grants the permissions defined in a role to a user or service account.


```yaml
cat <<EOF > roleBinding.yaml
apiVersion: rbac.authorization.k8s.io/v1
# This role binding allows "sa1" to list pods in the "nginx-ns" namespace.
# You need to already have a Role named "pod-reader" in that namespace.
kind: RoleBinding
metadata:
  name: read-pods
  namespace: nginx-ns
subjects:
# You can specify more than one "subject"
- kind: ServiceAccount
  name: sa1 # "name" is case sensitive
  apiGroup: ""
roleRef:
  # "roleRef" specifies the binding to a Role / ClusterRole
  kind: Role #this must be Role or ClusterRole
  name: sa1-list # this must match the name of the Role or ClusterRole you wish to bind to
  apiGroup: rbac.authorization.k8s.io
EOF
```

Let's create the RoleBinding in the namespace `nginx-ns`:
```sh
kubectl create -n nginx-ns -f roleBinding.yaml
```

# Test

Jump inside the Pod:
```sh
kubectl exec -it -n nginx-ns nginx-sa -- /bin/sh
```

Try to access the API:
```sh
curl --cacert /var/run/secrets/kubernetes.io/serviceaccount/ca.crt -H "Authorization: Bearer $(cat /var/run/secrets/kubernetes.io/serviceaccount/token)" https://kubernetes.default.svc/api/v1/namespaces/nginx-ns/pods
```

The output is quite large. I'm just showing the beginning, yours should be similar:
```
{
  "kind": "PodList",
  "apiVersion": "v1",
  "metadata": {
    "resourceVersion": "204840"
[...]
```

No more error. User account account `sa1` can list Pods 🎉

# Cleanup
Let's remove what was created earlier with the commands below:
```sh
kubectl delete -n nginx-ns -f roleBinding.yaml
kubectl delete -n nginx-ns -f role.yaml
kubectl delete -f nginx-pod.yaml
kubectl delete -f sa1.yaml
```

# References
[K8s Service Account](https://kubernetes.io/docs/concepts/security/service-accounts/)  
[Using RBAC Authorization](https://kubernetes.io/docs/reference/access-authn-authz/rbac/)  
[K8s API OVERVIEW](https://kubernetes.io/docs/reference/generated/kubernetes-api/v1.27/)  
