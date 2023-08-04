# BGP
BGP Control Plane provides a way for Cilium to advertise routes to connected routers by using the Border Gateway Protocol (BGP). BGP Control Plane makes `Pod networks` and/or `Services` of type LoadBalancer reachable from outside the cluster for environments that support BGP. Because BGP Control Plane does not program the datapath, do not use it to establish reachability within the cluster.

# Usage
Currently a single flag in the Cilium Agent exists to turn on the BGP Control Plane feature set.

If using Helm charts, the relevant values are the following:
```yaml
bgpControlPlane:
  enabled: true
```

When set to true the BGP Control Plane Controllers will be instantiated and will begin listening for `CiliumBGPPeeringPolicy` events. Currently, the BGP Control Plane will only work when IPAM mode is set to `cluster-pool` or `kubernetes`.

# BGP Peering
All BGP peering topology information is carried in a `CiliumBGPPeeringPolicy` CRD. `CiliumBGPPeeringPolicy` can be applied to one or more nodes based on its nodeSelector fields.

A Cilium node may only have a single `CiliumBGPPeeringPolicy` apply to it and if more than one does, it will apply no policy at all. Each `CiliumBGPPeeringPolicy` defines one or more `CiliumBGPVirtualRouter` configurations.

When these CRDs are written or read from the cluster the Controllers will take notice and perform the necessary actions to drive the BGP Control Plane to the desired state described by the policy.

Example of a policy in `yaml` form:
```sh
cat <<EOF > bgp.yaml
apiVersion: "cilium.io/v2alpha1"
kind: CiliumBGPPeeringPolicy
metadata:
  name: tor0
spec:
  nodeSelector:
    matchLabels:
      kubernetes.io/hostname: k8smaster1.isociel.com
  virtualRouters:
  - localASN: 65001
  # to advertise the CIDR block of Pods
    exportPodCIDR: true
    neighbors:
     - peerAddress: '192.168.13.40/24'
       peerASN: 65000
      #  eBGPMultihopTTL: 10
      #  connectRetryTimeSeconds: 120
      #  holdTimeSeconds: 90
      #  keepAliveTimeSeconds: 30
      #  gracefulRestart:
      #   enabled: true
      #   restartTimeSeconds: 120
    serviceSelector:
      # matchExpressions:
      # announce ALL services within the cluster
        # - {key: somekey, operator: NotIn, values: ['never-used-value']}
    serviceSelector:
      matchLabels:
        io.kubernetes.service.namespace: nginx-ns
EOF
```

Create a BGP peering:
```sh
kubectl create -f bgp.yaml
```

>I used a Ubuntu server with FRR as my `ToR` router

# References
[Cilium BGP Control Plane](https://docs.cilium.io/en/v1.13/network/bgp-control-plane/)  


# Load Balancer IPAM
LB IPAM has the notion of IP Pools which the administrator can create to tell Cilium which IP ranges can be used to allocate `EXTERNAL-IP` IPs from.

Below is a manifest to create two IP Pools:
- An IP Pools with both an IPv4 and IPv6 range named `blue-pool`
  - IPv4 is the TEST-NET-1, documentation and examples
- An IP Pools with IPv4 only and a selector based on the NameSpace named `red-pool`
  - IPv4 is the TEST-NET-2, documentation and examples
- An IP Pools with IPv4 only and a selector based on a *color* named `green-pool`
  - IPv4 is the TEST-NET-3, documentation and examples

```sh
cat <<EOF > ippool.yaml
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "blue-pool"
spec:
  cidrs:
  - cidr: "192.0.2.0/24"
  - cidr: "2004::0/64"
  serviceSelector:
    matchExpressions:
      - {key: color, operator: In, values: [blue, cyan]}
---
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "red-pool"
spec:
  cidrs:
  - cidr: "198.51.100.0/24"
  serviceSelector:
    matchLabels:
      io.kubernetes.service.namespace: nginx-ns
      # color: red
---
apiVersion: "cilium.io/v2alpha1"
kind: CiliumLoadBalancerIPPool
metadata:
  name: "green-pool"
spec:
  cidrs:
  - cidr: "203.0.113.0/24"
  serviceSelector:
    matchLabels:
      # io.kubernetes.service.namespace: nginx-ns
      color: green
EOF
```

### Create the Pool
```sh
kubectl create -f ippool.yaml
```

```
ciliumloadbalancerippool.cilium.io/blue-pool created
ciliumloadbalancerippool.cilium.io/red-pool created
ciliumloadbalancerippool.cilium.io/green-pool created
```

After adding the pool to the cluster, it appears like so:
```sh
kubectl get ippools
```

Output:
```
NAME         DISABLED   CONFLICTING   IPS AVAILABLE   AGE
blue-pool    false      False         65788           18s
green-pool   false      False         254             18s
red-pool     false      False         253             18s
```

# Nginx Service
I still had my Nginx service created in [Test Cilium](02-Test-Cilium.md).

```sh
kubectl get svc -n nginx-ns
```

The Nginx service is in NameSpace `nginx-ns` and in the IP Pool `red-pool` I matched against the namespace:
```
NAME        TYPE           CLUSTER-IP       EXTERNAL-IP      PORT(S)        AGE
nginx-svc   LoadBalancer   198.19.130.231   198.51.100.206   80:31211/TCP   25m
```

# BGP ToR
Check your ToR router if you received the `EXTERNAL-IP` assigned to the service. Your command will vary depending on the type of router you are using. This comes from **FRR** on Linux.
```sh
show bgp ipv4 unicast neighbors 192.168.13.61 received
```

```
BGP table version is 7, local router ID is 192.168.13.40, vrf id 0
Default local pref 100, local AS 65000
Status codes:  s suppressed, d damped, h history, * valid, > best, = multipath,
               i internal, r RIB-failure, S Stale, R Removed
Nexthop codes: @NNN nexthop's vrf id, < announce-nh-self
Origin codes:  i - IGP, e - EGP, ? - incomplete
RPKI validation codes: V valid, I invalid, N Not found

    Network          Next Hop            Metric LocPrf Weight Path
 *> 100.64.0.0/24    192.168.13.61                          0 65001 i
 *> 198.51.100.206/32
                    192.168.13.61                          0 65001 i

Total number of prefixes 2
```
