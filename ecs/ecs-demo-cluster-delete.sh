#!/bin/bash
# Olivier Corbun

AWS_REGION=us-east-1
ECS_CLUSTER=ecs-demo-cluster

# scale in
ecs-cli scale --capability-iam --size 0 --cluster $ECS_CLUSTER --region $AWS_REGION

# or just delete the cluster (takes time to recreate)
ecs-cli down --force --cluster $ECS_CLUSTER --region $AWS_REGION

# todo delete fargate resources
