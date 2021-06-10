#!/bin/bash

# do not run all at once! demo script
exit 0

AWS_REGION=us-east-1
EKS_CLUSTER=eks-demo-cluster
EKS_KEYPAIR=eks-demo-keypair
EKS_NODEGROUP=eks-demo-nodegroup
DOCKER_IMG=frontend
ECR_REPO=$DOCKER_IMG

# eks demo
# eksctl is for cluster management
# kubectl is for container management

# cluster status
aws eks list-clusters --region=$AWS_REGION --output=json
aws eks describe-cluster --name=$EKS_CLUSTER --region=$AWS_REGION --output=json

# previously, behind the scene, this was executed:
# aws eks update-kubeconfig --name $EKS_CLUSTER
# so, kubectl points to our demo cluster
kubectl config view
kubectl cluster-info

# see all the Kubernetes internals
# by default, the internals run within the kube-system namespace
kubectl get all --all-namespaces

# get full repo name from ECR: <account>.dkr.ecr.<region>.amazonaws.com/<repo>:<version>
QUERY=repositories[?repositoryName==\`$ECR_REPO\`].repositoryUri
IMG_URI=$(aws ecr describe-repositories --region=$AWS_REGION --query=$QUERY --output=text):01
echo $IMG_URI

# create a swan pod (1) and scale it out
kubectl create namespace apps
kubectl create deployment swan --image=$IMG_URI -n apps
kubectl describe deployment/swan -n apps
kubectl scale deployment/swan -n apps --replicas=2

kubectl get pods -n apps

# expose swan as a service behind a lb (default ELB Classic Load Balancer)
# service.beta.kubernetes.io/aws-load-balancer-type=nlb (Kubernetes v1.15)
kubectl expose deployment/swan --port=80 --target-port=8080 --type=LoadBalancer --name=web -n apps
SWAN_URL=http://$(kubectl get service/web  -n apps -o=jsonpath="{.status.loadBalancer.ingress..hostname}")
open -a Safari $SWAN_URL

# send traffic
locust --host=$SWAN_URL


# ALTERNATIVE
kubectl create deployment nginx --image=nginx:latest
kubectl describe deployment/nginx
kubectl scale deployment/nginx --replicas=4
kubectl describe deployment/nginx
kubectl expose deployment/nginx --port=80 --target-port=80 --type=LoadBalancer --name=web
