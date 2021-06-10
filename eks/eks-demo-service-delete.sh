#!/bin/bash
# Olivier Corbun

AWS_REGION=us-east-1
EKS_CLUSTER=eks-demo-cluster
EKS_NODEGROUP=eks-demo-nodegroup

# cleanup pods
kubectl scale deployment/swan -n apps --replicas=0
kubectl delete deployment/swan service/web -n apps

# alternatively to destroying cluster, scale in to 1!
eksctl scale nodegroup --cluster $EKS_CLUSTER --name $EKS_NODEGROUP --nodes 1
