#!/bin/bash

AWS_REGION=us-east-1
ECS_CLUSTER=ecs-demo-cluster
DOCKER_IMG=frontend
ECR_REPO=$DOCKER_IMG
ECS_EC2_TASK_DEF=frontend-ec2

# Cleanup

# stop ALL tasks

# manually
# open https://console.aws.amazon.com/ecs/home?region=$AWS_REGION#/clusters/$ECS_CLUSTER/tasks

# automatically
TASKS=$(aws ecs list-tasks --region $AWS_REGION \
  --cluster=$ECS_CLUSTER --desired-status RUNNING --family $ECS_EC2_TASK_DEF \
  --query='taskArns' --output text)
for TASK in $( echo "$TASKS" ); do
    echo Task $TASK is being stopped...
    aws ecs stop-task --cluster=$ECS_CLUSTER --task $TASK
done

# deregister task def
ECS_EC2_TASK_DEF_ARN=$(aws ecs describe-task-definition --task-definition $ECS_EC2_TASK_DEF --query='taskDefinition.taskDefinitionArn' --output text)
aws ecs deregister-task-definition --task-definition $ECS_EC2_TASK_DEF_ARN
