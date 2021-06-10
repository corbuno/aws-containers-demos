#!/bin/bash

# do not run all at once! demo script
exit 0

AWS_REGION=us-east-1
ECS_CLUSTER=ecs-demo-cluster
DOCKER_IMG=frontend
ECR_REPO=$DOCKER_IMG
ECS_EC2_TASK_DEF=frontend-ec2
ECS_EC2_SERVICE=$ECS_EC2_TASK_DEF

# get full repo name from ECR: <account>.dkr.ecr.<region>.amazonaws.com/<repo>:<version>
QUERY=repositories[?repositoryName==\`$ECR_REPO\`].repositoryUri
IMG_URI=$(aws ecr describe-repositories --region $AWS_REGION --query=$QUERY --output=text):01
echo $IMG_URI

# prepare task definition and register it with ECS
cp ecs-demo-task-def-ORIGINAL.json ecs-demo-task-def.json
sed -i "" "s|<IMG_URI>|$IMG_URI|g" ecs-demo-task-def.json
sed -i "" "s|<ECS_EC2_TASK_DEF>|$ECS_EC2_TASK_DEF|g" ecs-demo-task-def.json
aws ecs register-task-definition --region $AWS_REGION \
  --cli-input-json file://ecs-demo-task-def.json
aws ecs list-task-definitions --region $AWS_REGION 
open https://$AWS_REGION.console.aws.amazon.com/ecs/home?region=$AWS_REGION#/taskDefinitions

# run task
aws ecs run-task --cluster=$ECS_CLUSTER --region $AWS_REGION \
  --task-definition=$ECS_EC2_TASK_DEF --launch-type EC2 --count=4
aws ecs list-tasks --region $AWS_REGION --cluster=$ECS_CLUSTER --launch-type EC2
TASKS=$(aws ecs list-tasks --cluster=$ECS_CLUSTER --launch-type EC2 --query='taskArns' --output text)
for TASK in $TASKS; do
    CONTAINER=$(aws ecs describe-tasks --cluster=$ECS_CLUSTER --tasks $TASK --query 'tasks[0].containerInstanceArn' --output text)
    INSTANCE=$(aws ecs describe-container-instances --cluster=$ECS_CLUSTER --container $CONTAINER --query 'containerInstances[0].ec2InstanceId' --output text)
    HOST=$(aws ec2 describe-instances --instance $INSTANCE --query 'Reservations[0].Instances[0].PublicDnsName' --output text)
    #open http://$HOST
done
aws ecs list-tasks --cluster $ECS_CLUSTER --launch-type EC2 --output text | wc -l


