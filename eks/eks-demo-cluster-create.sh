#!/bin/bash

# do not run all at once! demo script
exit 0

AWS_REGION=us-east-1
EKS_CLUSTER=eks-demo-cluster
EKS_KEYPAIR=eks-demo-keypair
EKS_NODEGROUP=eks-demo-nodegroup

# key-pair
aws ec2 create-key-pair \
  --key-name $EKS_KEYPAIR \
  --query 'KeyMaterial' \
  --output text > $EKS_KEYPAIR.pem &&
chmod 400 $EKS_KEYPAIR.pem

# Create cluster with Fargate and 2 EC2 instances, Spot and SSM enabled
eksctl create cluster \
  --name $EKS_CLUSTER \
  --version 1.20 \
  --region $AWS_REGION \
  --zones "$AWS_REGION"a,"$AWS_REGION"b \
  --vpc-cidr 10.1.0.0/16 \
  --nodegroup-name $EKS_NODEGROUP \
  --node-type t2.small \
  --nodes 2 --nodes-min 1 --nodes-max 4 \
  --ssh-access --ssh-public-key $EKS_KEYPAIR \
  --enable-ssm --spot --managed --fargate

# Managing users or IAM roles for your cluster
# If CLI user is different from AWS Console user, the AWS Console user/group/role has to be added to configmap aws-auth
kubectl edit -n kube-system configmap/aws-auth
# see aws-auth.yml

# Container Insights
# add CloudWatchAgentServerPolicy to EC2 role
curl https://raw.githubusercontent.com/aws-samples/amazon-cloudwatch-container-insights/latest/k8s-deployment-manifest-templates/deployment-mode/daemonset/container-insights-monitoring/quickstart/cwagent-fluentd-quickstart.yaml | \
  sed "s/{{cluster_name}}/$EKS_CLUSTER/;s/{{region_name}}/$AWS_REGION/" | kubectl apply -f -

# get EKS AMI for k8s 1.20
aws ssm get-parameter \
  --name /aws/service/eks/optimized-ami/1.20/amazon-linux-2/recommended/image_id \
  --region $AWS_REGION --query "Parameter.Value" --output text
