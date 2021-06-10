#!/bin/bash

AWS_REGION=us-east-1
DOCKER_IMG=frontend
ECR_REPO=$DOCKER_IMG
OUTPUT=text

# repositories
echo . ECR REPOSITORIES
aws ecr describe-repositories --output $OUTPUT

# images
echo . ECR IMAGES
if [[ $(aws ecr describe-repositories --output text | grep $ECR_REPO) ]];
then
aws ecr list-images --repository-name $ECR_REPO --output $OUTPUT
fi

# task definitions
echo . ECS TASK DEFINITIONS
aws ecs list-task-definitions --output $OUTPUT

# clusters
echo . ECS CLUSTERS
aws ecs list-clusters --output $OUTPUT

# loop over each cluster
for ECS_CLUSTER in `aws ecs list-clusters --output text | sed 's|.*/||'`
do

# containers
echo . ECS INSTANCES \($ECS_CLUSTER\)
aws ecs list-container-instances --cluster $ECS_CLUSTER --output $OUTPUT

# services
echo . ECS SERVICES \($ECS_CLUSTER\)
aws ecs list-services --cluster $ECS_CLUSTER --output $OUTPUT

# tasks
echo . ECS TASKS \($ECS_CLUSTER\)
aws ecs list-tasks --cluster $ECS_CLUSTER --output $OUTPUT

done
