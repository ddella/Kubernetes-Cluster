#!/bin/bash
#
# This script copy the certificates and private keys to each etcd node.
#
# HOWTO use it: ./13-scp.sh
#
# Works with 'bash' and 'zsh' shell on macOS and Linux. Make sure you have OpenSSL *** in your PATH ***.
#
# *WARNING*
# This script was made for educational purposes ONLY.
# USE AT YOUR OWN RISK!"

# Modify the variables to reflect your environment
USER=daniel
ETCD_NODES=( k8setcd1 k8setcd2 k8setcd3 )
CA_CERT=etcd-ca.crt

for NODE in "${ETCD_NODES[@]}"; do
  printf "Copying files on: %s\n" ${NODE}
  scp ${CA_CERT} ${USER}@${NODE}:/home/${USER}/.
  scp ${NODE}.crt ${USER}@${NODE}:/home/${USER}/.
  scp ${NODE}.key ${USER}@${NODE}:/home/${USER}/.
  printf "\n"
done
