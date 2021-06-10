#!/bin/bash

# do not run all at once! demo script
exit 0

AWS_REGION=us-east-1
APPRUNNER_TASKS_ROLE=apprunner-ECRAccessRole
DOCKER_IMG=frontend
SERVICE_NAME=$DOCKER_IMG

# iam role for ecs tasks
aws iam create-role --region $AWS_REGION --role-name $APPRUNNER_TASKS_ROLE \
  --assume-role-policy-document file://apprunner-policy.json \
  --query 'Role.Arn' \
  --output text &&
aws iam attach-role-policy --region $AWS_REGION --role-name $APPRUNNER_TASKS_ROLE \
  --policy-arn arn:aws:iam::aws:policy/service-role/AWSAppRunnerServicePolicyForECRAccess

# get IAM role
IAM_ROLE=$(aws iam get-role --region $AWS_REGION --role-name $APPRUNNER_TASKS_ROLE --query=Role.Arn --output=text)

# get full repo name from ECR: <account>.dkr.ecr.<region>.amazonaws.com/<repo>:<version>
QUERY=repositories[?repositoryName==\`$ECR_REPO\`].repositoryUri
IMG_URI=$(aws ecr describe-repositories --region $AWS_REGION --query=$QUERY --output=text):01
echo $IMG_URI

# prepare service specification
cp frontend-apprunner-ORIGINAL.json frontend-apprunner.json
sed -i "" "s|<IMG_URI>|$IMG_URI|g" frontend-apprunner.json
sed -i "" "s|<IAM_ROLE>|$IAM_ROLE|g" frontend-apprunner.json

# create service (since AWS CLI v2.2.6)
aws apprunner create-service --region $AWS_REGION \
  --service-name ${SERVICE_NAME} \
  --source-configuration file://frontend-apprunner.json
