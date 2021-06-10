#!/bin/bash

# do not run all at once! demo script
exit 0

AWS_REGION=us-east-1
ECS_CLUSTER=ecs-demo-cluster
ECS_KEYPAIR=ecs-demo-keypair
ECS_SG=ecs-demo-sg
ECS_LB=ecs-demo-lb
ECS_TG=ecs-demo-tg
ECS_EC2_ROLE=ecs-demo-ec2-role
ECS_TASKS_ROLE=ecs-demo-tr
CF_STACK=amazon-ecs-cli-setup-$ECS_CLUSTER
ECS_SERVICE_PORT=8080

# key-pair
aws ec2 create-key-pair \
--key-name $ECS_KEYPAIR \
--query 'KeyMaterial' \
--output text > $ECS_KEYPAIR.pem &&
chmod 400 $ECS_KEYPAIR.pem

# Container Insights enabled in account
aws ecs put-account-setting --name "containerInsights" --value "enabled"


# METHOD 1 __________________________________
# ECS CLI

# ec2 role (TO BE FIXED)
aws iam create-role --region $AWS_REGION \
  --role-name $ECS_EC2_ROLE \
  --assume-role-policy-document file://ecsEC2InstanceRolePolicy.json
aws iam attach-role-policy --region $AWS_REGION \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2RoleforSSM \
  --role-name $ECS_EC2_ROLE
aws iam attach-role-policy --region $AWS_REGION \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonEC2ContainerServiceforEC2Role \
  --role-name $ECS_EC2_ROLE

# ecs cluster
ecs-cli up --region $AWS_REGION --cluster $ECS_CLUSTER \
  --launch-type EC2 \
  --keypair $ECS_KEYPAIR \
  --instance-role myEC2RoleforSSM \
  --spot-price 1 \
  --port 80 --cidr 0.0.0.0/0 \
  --size 2 --instance-type t2.medium \
  --tags 'Name=ecs-demo'

# optional if enabled per account
aws ecs update-cluster-settings --region $AWS_REGION --cluster $ECS_CLUSTER \
  --settings name=containerInsights,value=enabled

# security group extra rules
SG=$(aws cloudformation list-stack-resources --region $AWS_REGION \
  --stack-name=$CF_STACK --query 'StackResourceSummaries[?ResourceType==`AWS::EC2::SecurityGroup`].PhysicalResourceId' --output text)
aws ec2 authorize-security-group-ingress --region $AWS_REGION --group-id $SG \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 8080, "ToPort": 8080, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow HTTP"}]}]'
aws ec2 authorize-security-group-ingress --region $AWS_REGION --group-id $SG \
  --ip-permissions '[{"IpProtocol": "tcp", "FromPort": 22, "ToPort": 22, "IpRanges": [{"CidrIp": "0.0.0.0/0", "Description": "Allow SSH"}]}]'

# fargate resources
VPC=$(aws cloudformation list-stack-resources --region $AWS_REGION \
  --stack-name=$CF_STACK --query 'StackResourceSummaries[?ResourceType==`AWS::EC2::VPC`].PhysicalResourceId' --output text)
SUBNETS_STRINGS=$(aws cloudformation list-stack-resources --region $AWS_REGION \
  --stack-name=$CF_STACK --query 'StackResourceSummaries[?ResourceType==`AWS::EC2::Subnet`].PhysicalResourceId' \
  --output text | sed 's/[[:blank:]]s/ s/g')
# load balancer
LB_ARN=$(aws elbv2 create-load-balancer --region $AWS_REGION --name $ECS_LB \
  --type application \
  --tags Key=Name,Value=ecs-demo \
  --security-groups $SG \
  --subnets $SUBNETS_STRINGS \
  --query 'LoadBalancers[0].LoadBalancerArn' | sed 's/"//g')
# target group
TG_ARN=$(aws elbv2 create-target-group --region $AWS_REGION --name $ECS_TG \
  --protocol HTTP --port $ECS_SERVICE_PORT \
  --target-type ip \
  --vpc-id $VPC \
  --query 'TargetGroups[0].TargetGroupArn' | sed 's/"//g')
# listener to attach lb and target
aws elbv2 create-listener --region $AWS_REGION --load-balancer-arn $LB_ARN \
  --protocol HTTP --port 80 \
  --default-actions Type=forward,TargetGroupArn=$TG_ARN
# iam role for ecs tasks
aws iam create-role --region $AWS_REGION --role-name $ECS_TASKS_ROLE \
  --assume-role-policy-document file://ecsTasksRolePolicy.json \
  --query 'Role.Arn' \
  --output text &&
aws iam attach-role-policy --region $AWS_REGION --role-name $ECS_TASKS_ROLE \
  --policy-arn arn:aws:iam::aws:policy/service-role/AmazonECSTaskExecutionRolePolicy


# EC2 AMI
AWS_ECS_AMI_ID=$(aws ssm get-parameters \
--names "/aws/service/ecs/optimized-ami/amazon-linux-2/recommended/image_id" \
--query 'Parameters[0].Value' \
--output text)
echo $AWS_ECS_AMI_ID

