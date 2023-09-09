# How to save the database
Guide to taking a snapshot of the etcd database.

## Save
snapshot to save point-in-time snapshot of etcd database:

> [!IMPORTANT]  
> Snapshot can only be requested from one `etcd` node, so `--endpoints` flag should contain only one endpoint.

```sh
unset ETCDCTL_ENDPOINTS
ENDPOINT=k8setcd1:2379
export ETCDCTL_CACERT=./etcd-ca.crt
export ETCDCTL_CERT=./k8setcd1.crt
export ETCDCTL_KEY=./k8setcd1.key
etcdctl --endpoints=${ENDPOINT} snapshot save snapshot_1.db
```

> [!IMPORTANT]  
> Make sure to unset environment variable `ETCDCTL_ENDPOINTS`

Output:
```
Snapshot saved at my.db
```

## Status of snapshot
```sh
etcdutl --write-out=table snapshot status snapshot_1.db
```

Output
```
+----------+----------+------------+------------+
|   HASH   | REVISION | TOTAL KEYS | TOTAL SIZE |
+----------+----------+------------+------------+
| 3501943d |        3 |         10 |      20 kB |
+----------+----------+------------+------------+
```

## Write Data
```sh
export ETCDCTL_API=3
export ETCDCTL_ENDPOINTS=https://k8setcd1:2379,https://k8setcd2.isociel.com:2379,https://192.168.13.37:2379
export ETCDCTL_CACERT=./etcd-ca.crt
export ETCDCTL_CERT=./k8setcd1.crt
export ETCDCTL_KEY=./k8setcd1.key
etcdctl put snap "This is after the backup"
```

Read the data back:
```sh
etcdctl get snap
```

Output:
```
snap
This is after the backup
```

# How to restore the database
> [!IMPORTANT]  
> You need to execute the commands on **every** node of the cluster.
> Use `sudo` to avoid the message `Error: mkdir /var/lib/etcd-backup: permission denied`.

The command to restore is almost identical of the one to save a snapshot. The only difference is that we need to provide a new data directory where we will copy the cluster data from the `snapshot_1.db` database.
```sh
NODE=$(hostname -s)
export ETCDCTL_API=3
export ETCDCTL_ENDPOINTS=https://k8setcd1:2379,https://k8setcd2.isociel.com:2379,https://192.168.13.37:2379
export ETCDCTL_CACERT=/etc/etcd/pki/etcd-ca.crt
export ETCDCTL_CERT=/etc/etcd/pki/${NODE}.crt
export ETCDCTL_KEY=/etc/etcd/pki/${NODE}.key

sudo etcdutl snapshot restore snapshot_1.db --data-dir="/var/lib/etcd-backup"
sudo sed -i 's/data-dir: "\/var\/lib\/etcd"/data-dir: "\/var\/lib\/etcd-backup"/' /etc/etcd/etcd.conf
sudo systemctl restart etcd
```

