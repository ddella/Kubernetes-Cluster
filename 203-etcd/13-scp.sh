#!/bin/sh

USER=daniel
ETCD_NODES=( k8setcd1 k8setcd2 k8setcd3 )

for NODE in "${ETCD_NODES[@]}"; do
  echo "Copying files on: ${NODE}"
  scp ca.pem $USER@$NODE:/home/${USER}/etcd-ca.crt
  scp $NODE-crt.pem $USER@$NODE:/home/${USER}/server.crt
  scp $NODE-key.pem $USER@$NODE:/home/${USER}/server.key
  echo ""
done
