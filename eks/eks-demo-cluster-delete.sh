#!/bin/bash

# do not run all at once! demo script
exit 0

AWS_REGION=us-east-1
EKS_CLUSTER=eks-demo-cluster
EKS_NODEGROUP=eks-demo-nodegroup

# destroy cluster (takes time to recreate!)
#kubectl get svc --all-namespaces
#kubectl delete svc ENTER_SERVICE_NAME_TODO!!!!!!!!!
eksctl delete cluster --name=$EKS_CLUSTER --region=$AWS_REGION

# delete EBS volumes for Grafana and Prometheus left behind
volumes=$(aws ec2 describe-volumes --region=$AWS_REGION \
  --query="Volumes[?Tags[?Key=='kubernetes.io/created-for/pvc/name']].VolumeId" \
  --output=text)
nb=$(echo "$volumes" | wc -w)
for ((v=1; v<=$nb; v++)) do
  vol=$(cut -f$v <<<$volumes)
  aws ec2 delete-volume --region=$AWS_REGION --volume-id $vol
done

# or just scale in!
eksctl scale nodegroup --region=$AWS_REGION --cluster=$EKS_CLUSTER --nodes=1 --name=$EKS_NODEGROUP
