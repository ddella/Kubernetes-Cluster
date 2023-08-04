# Get bgpconfig
Get the BGP configuration:
```sh
calicoctl get bgpconfig -o yaml
```

```
apiVersion: projectcalico.org/v3
items:
- apiVersion: projectcalico.org/v3
  kind: BGPConfiguration
  metadata:
    creationTimestamp: "2023-06-10T15:29:12Z"
    managedFields:
    - apiVersion: projectcalico.org/v3
      fieldsType: FieldsV1
      fieldsV1:
        f:spec:
          f:asNumber: {}
          f:bindMode: {}
          f:communities: {}
          f:logSeverityScreen: {}
          f:nodeMeshMaxRestartTime: {}
          f:nodeToNodeMeshEnabled: {}
          f:serviceClusterIPs: {}
      manager: kubectl-create
      operation: Update
      time: "2023-06-10T15:29:12Z"
    - apiVersion: projectcalico.org/v3
      fieldsType: FieldsV1
      fieldsV1:
        f:spec:
          f:prefixAdvertisements: {}
          f:serviceExternalIPs: {}
      manager: kubectl-replace
      operation: Update
      time: "2023-06-11T15:35:04Z"
    name: default
    resourceVersion: "989788"
    uid: b3c3e601-cda2-4a89-9f5e-9d85393ea6f6
  spec:
    asNumber: 65001
    bindMode: NodeIP
    communities:
    - name: bgp-cluster-community
      value: 65001:100
    logSeverityScreen: Info
    nodeMeshMaxRestartTime: 2m0s
    nodeToNodeMeshEnabled: true
    prefixAdvertisements:
    - cidr: 10.96.0.0/12
      communities:
      - bgp-cluster-community
      - 65001:123
      - 65001:456
    serviceClusterIPs:
    - cidr: 10.96.0.0/12
    serviceExternalIPs:
    - cidr: 2.2.2.2/32
    - cidr: 172.31.255.0/24
kind: BGPConfigurationList
metadata:
  resourceVersion: "1206260"
```

# Get BGP Peer
```sh
calicoctl get bgppeer -o yaml
```

```
apiVersion: projectcalico.org/v3
items:
- apiVersion: projectcalico.org/v3
  kind: BGPPeer
  metadata:
    creationTimestamp: "2023-06-10T16:40:01Z"
    managedFields:
    - apiVersion: projectcalico.org/v3
      fieldsType: FieldsV1
      fieldsV1:
        f:spec:
          f:asNumber: {}
          f:peerIP: {}
      manager: kubectl-create
      operation: Update
      time: "2023-06-10T16:40:01Z"
    - apiVersion: projectcalico.org/v3
      fieldsType: FieldsV1
      fieldsV1:
        f:spec:
          f:nodeSelector: {}
      manager: kubectl-replace
      operation: Update
      time: "2023-06-11T15:04:16Z"
    name: k8smaster1
    resourceVersion: "984611"
    uid: f0fb6bc8-12e7-48fc-8f7b-9596d52d7375
  spec:
    asNumber: 65000
    nodeSelector: kubernetes.io/hostname in {'k8smaster1.isociel.com','k8sworker1.isociel.com','k8sworker2.isociel.com','k8sworker3.isociel.com'}
    peerIP: 192.168.13.39
kind: BGPPeerList
metadata:
  resourceVersion: "1205950"
```

# Get Felix Configuration
```sh
calicoctl get felixconfiguration -o yaml
```

```
apiVersion: projectcalico.org/v3
items:
- apiVersion: projectcalico.org/v3
  kind: FelixConfiguration
  metadata:
    creationTimestamp: "2023-06-03T14:01:30Z"
    generation: 1
    managedFields:
    - apiVersion: crd.projectcalico.org/v1
      fieldsType: FieldsV1
      fieldsV1:
        f:spec:
          .: {}
          f:bpfLogLevel: {}
          f:healthPort: {}
      manager: operator
      operation: Update
      time: "2023-06-03T14:01:30Z"
    name: default
    resourceVersion: "830878"
    uid: deb65f83-9958-49f7-91ec-888e7af73de9
  spec:
    bpfEnabled: false
    bpfExternalServiceMode: Tunnel
    bpfKubeProxyIptablesCleanupEnabled: true
    bpfLogLevel: ""
    floatingIPs: Disabled
    healthPort: 9099
    logSeverityScreen: Info
    reportingInterval: 0s
kind: FelixConfigurationList
metadata:
  resourceVersion: "1206051"
```

# References
[calicoctl user reference](https://docs.tigera.io/calico/latest/reference/calicoctl/overview)  

