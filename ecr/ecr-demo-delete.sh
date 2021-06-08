#!/bin/bash

AWS_REGION=us-east-1
DOCKER_IMG=frontend
ECR_REPO=$DOCKER_IMG

# Cleanup

# delete remote image in ecr
aws ecr batch-delete-image --region $AWS_REGION --repository-name $ECR_REPO --image-ids imageTag=01
# delete remote repo in ecr
aws ecr delete-repository --region $AWS_REGION --repository-name $ECR_REPO --force

# stop local container
CONTAINER_ID=`docker ps --filter ancestor=$DOCKER_IMG --format {{.ID}}`
echo $CONTAINER_ID
docker container stop $DOCKER_IMG
docker container rm $DOCKER_IMG
docker container ps -a

# remove images from local repo
DOCKER_IMG_ID=$(docker images --filter=reference=$DOCKER_IMG --format "{{.ID}}")
docker image rm $DOCKER_IMG_ID --force

