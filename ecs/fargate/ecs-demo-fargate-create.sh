#!/bin/bash

# do not run all at once! demo script
exit 0

AWS_REGION=us-east-1
ECS_CLUSTER=ecs-demo-cluster
ECS_FARGATE_TASK_DEF=frontend-fargate
ECS_FARGATE_SERVICE=$ECS_FARGATE_TASK_DEF
CF_STACK=amazon-ecs-cli-setup-$ECS_CLUSTER
ECS_LB=ecs-demo-lb
ECS_TG=ecs-demo-tg
ECS_TASKS_ROLE=ecs-demo-tr


# prepare task definition and register it with ECS
cp fargate-demo-task-def-ORIGINAL.json fargate-demo-task-def.json
sed -i "" "s|<ECS_FARGATE_TASK_DEF>|$ECS_FARGATE_TASK_DEF|g" fargate-demo-task-def.json
# image uri
IMG_URI=$(aws ecr describe-repositories --region $AWS_REGION --query='repositories[?repositoryName==`frontend`].repositoryUri' --output=text):01
sed -i "" "s|<IMG_URI>|$IMG_URI|" fargate-demo-task-def.json
# ecs role arn
ROLE_ARN=$(aws iam get-role --region $AWS_REGION --role-name $ECS_TASKS_ROLE --query 'Role.Arn' --output text)
sed -i "" "s|<ROLE_ARN>|$ROLE_ARN|" fargate-demo-task-def.json

# register
aws ecs register-task-definition --region $AWS_REGION --cli-input-json file://fargate-demo-task-def.json
aws ecs list-task-definitions --region $AWS_REGION --output table
open https://us-east-1.console.aws.amazon.com/ecs/home?region=us-east-1#/taskDefinitions

# fetch data
SG=$(aws cloudformation list-stack-resources --region $AWS_REGION --stack-name=$CF_STACK \
  --query 'StackResourceSummaries[?ResourceType==`AWS::EC2::SecurityGroup`].PhysicalResourceId' --output text)
SUBNETS_COMMA=$(aws cloudformation list-stack-resources --region $AWS_REGION --stack-name=$CF_STACK \
  --query 'StackResourceSummaries[?ResourceType==`AWS::EC2::Subnet`].PhysicalResourceId' --output text | sed 's/[[:blank:]]s/,s/g')
QUERY=TargetGroups[?TargetGroupName==\`$ECS_TG\`].TargetGroupArn
TARGETGROUPARN=$(aws elbv2 describe-target-groups --region $AWS_REGION --query=$QUERY --output=text)

# ecs service
aws ecs create-service --region $AWS_REGION --cluster $ECS_CLUSTER \
  --service-name $ECS_FARGATE_SERVICE \
  --task-definition $ECS_FARGATE_TASK_DEF \
  --desired-count 4 \
  --capacity-provider-strategy "capacityProvider=FARGATE_SPOT,weight=1,base=0" \
  --scheduling-strategy REPLICA \
  --load-balancers \
    "targetGroupArn=$TARGETGROUPARN,containerName=$ECS_FARGATE_TASK_DEF,containerPort=8080" \
  --network-configuration \
    "awsvpcConfiguration={assignPublicIp=ENABLED,subnets=[$SUBNETS_COMMA],securityGroups=[$SG]}"

# browse to load balancer for that service
ELB_URL=$(aws elbv2 describe-load-balancers --region $AWS_REGION --name $ECS_LB --query "LoadBalancers[0].DNSName" | sed 's/"//g')
echo $ELB_URL
open http://$ELB_URL

# scale out
aws ecs update-service --region $AWS_REGION --cluster=$ECS_CLUSTER --service=$ECS_FARGATE_SERVICE --desired-count=8
aws ecs list-tasks --region $AWS_REGION --cluster $ECS_CLUSTER  --launch-type FARGATE --output text | wc -l

