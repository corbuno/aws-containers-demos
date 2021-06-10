#!/bin/bash
# Olivier Corbun

AWS_REGION=us-east-1
ECS_CLUSTER=ecs-demo-cluster
ECS_FARGATE_TASK_DEF=frontend-fargate
ECS_FARGATE_SERVICE=$ECS_FARGATE_TASK_DEF

# cleanup

# scale in
aws ecs update-service --region $AWS_REGION --cluster=$ECS_CLUSTER --service=$ECS_FARGATE_SERVICE --desired-count=0

# stop ALL tasks (speed up things)
TASKS=$(aws ecs list-tasks --region $AWS_REGION \
  --cluster=$ECS_CLUSTER --desired-status RUNNING --family $ECS_FARGATE_TASK_DEF \
  --query='taskArns' --output text)
for TASK in $( echo "$TASKS" ); do
    echo Task $TASK is being stopped...
    aws ecs stop-task --region $AWS_REGION --cluster=$ECS_CLUSTER --task $TASK
done

# delete ecs service
aws ecs delete-service --region $AWS_REGION --cluster $ECS_CLUSTER --service $ECS_FARGATE_SERVICE --force

# deregister task def
ECS_FARGATE_TASK_DEF_ARN=$(aws ecs describe-task-definition --region $AWS_REGION --task-definition $ECS_FARGATE_TASK_DEF \
  --query='taskDefinition.taskDefinitionArn' --output text)
aws ecs deregister-task-definition --region $AWS_REGION --task-definition $ECS_FARGATE_TASK_DEF_ARN
