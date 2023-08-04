# Install `etcdctl`
`etcd` is distributed, reliable key-value store for the most critical data of a distributed system. i=It's a strongly consistent, distributed key-value store that provides a reliable way to store data that needs to be accessed by a distributed system or cluster of machines. It gracefully handles leader elections during network partitions and can tolerate machine failure, even in the leader node.

`etcdctl` is a command line tool for interacting with the `etcd` database(s) in Kubernetes.

## Install Latest
```sh
export VER=$(curl -s https://api.github.com/repos/etcd-io/etcd/releases/latest|grep tag_name | cut -d '"' -f 4)
curl -LO https://github.com/etcd-io/etcd/releases/download/${VER}/etcd-${VER}-linux-amd64.tar.gz
tar xvf etcd-${VER}-linux-amd64.tar.gz
cd etcd-${VER}-linux-amd64
sudo cp etcdctl etcdutl /usr/local/bin/
sudo chown root:adm /usr/local/bin/etcdctl /usr/local/bin/etcdutl
```

## Verify installation
```sh 
etcdctl version
etcdutl version
```

## Cleanup
```sh
cd ..
rm -rf etcd-${VER}-linux-amd64
rm etcd-${VER}-linux-amd64.tar.gz
unset VER
```

# References
[Main site](https://etcd.io/docs/v3.4/dev-guide/interacting_v3/)  
[GitHub](https://github.com/etcd-io/etcd/tree/main/etcdctl)  
[Libraries and tools](https://etcd.io/docs/v3.5/integrations/)
