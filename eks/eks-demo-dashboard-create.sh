#!/bin/bash

# do not run all at once! demo script
exit 0

# based on https://docs.aws.amazon.com/eks/latest/userguide/dashboard-tutorial.html

AWS_REGION=us-east-1
EKS_CLUSTER=eks-demo-cluster

# install metrics (once)
#kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/download/v0.3.7/components.yaml
kubectl apply -f https://github.com/kubernetes-sigs/metrics-server/releases/latest/download/components.yaml

# install dashboard (once)
kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v2.2.0/aio/deploy/recommended.yaml

# Creds
kubectl apply -f eks-admin-service-account.yaml

# grab a new token
kubectl -n kube-system describe secret $(kubectl -n kube-system get secret | grep eks-admin | awk '{print $1}')

# Start Proxy
kubectl proxy --address 0.0.0.0 --accept-hosts '.*' &

# API version
curl http://localhost:8001/api/

# login
open http://localhost:8001/api/v1/namespaces/kubernetes-dashboard/services/https:kubernetes-dashboard:/proxy/#!/login


# creds for another user (admin must add new mapUsers after mapRoles)
# data: 
#   mapUsers:
#     - userarn: arn:aws:iam::12345678:user/foo
#       username: foo
#       groups:
#         - system:masters
kubectl edit -n kube-system configmap/aws-auth
# then user foo can run
aws eks update-kubeconfig --region= $AWS_REGION --name $EKS_CLUSTER



# Installing the Kubernetes Dashboard (OLD STYLE)
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/dashboard/v1.10.1/src/deploy/recommended/kubernetes-dashboard.yaml
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/heapster.yaml
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/influxdb/influxdb.yaml
#kubectl apply -f https://raw.githubusercontent.com/kubernetes/heapster/master/deploy/kube-config/rbac/heapster-rbac.yaml