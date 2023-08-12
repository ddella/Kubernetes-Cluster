#!/bin/bash

# 1. Extract an image from the local Docker repo and save it as a ‘.tar’ file
# 2. Copy the '.tar' file to all the Worker Node in a K8s cluster
# 3. Import the '.tar' file in the local K8s repository, so it can be used to deploy Pods

# Make sure you have the file to permit the 'USER' to sudo without password. Use wisely 😉
# echo "${USER} ALL=(ALL:ALL) NOPASSWD: ALL" | sudo tee /etc/sudoers.d/${USER} > /dev/null

# Docker image
DOCKER_IMAGE=php82_nginx125
# Docker image TAG
DOCKER_TAG=3.18.2

# User
USER=daniel

# List of all Worker Nodes in your K8s cluster
K8s_NODES=('k8sworker1' 'k8sworker2' 'k8sworker3')

# Domain name for the K8s Nodes
DNS_SUFFIX="EXAMPLE.COM”

docker save ${DOCKER_IMAGE):${DOCKER_TAG} -o ${DOCKER_IMAGE}.tar

for NODE in "${K8S_NODES[@]}"
do
  echo "scp file ${DOCKER_IMAGE}.tar on node $NODE.$DNS_SUFFIX"
  scp ${DOCKER_IMAGE}.tar $USER@$NODE.$DNS_SUFFIX:/tmp/.

  echo "Import image /${DOCKER_IMAGE}.tar in K8s local repo on node $NODE.$DNS_SUFFIX"
  ssh $NODE "sudo nerdctl --namespace=k8s.io load -i /tmp/${DOCKER_IMAGE}.tar && \
  rm -f ${DOCKER_IMAGE}.tar"

  echo "Done for node ${NODE}.${DNS_SUFFIX} ..."
  echo ""
